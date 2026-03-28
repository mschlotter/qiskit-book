import json
import os
from pathlib import Path
from typing import Set, Tuple
from urllib.parse import urljoin

import process_config as pc

# --- Helper Functions ---

def replace_links(
    line: str, ipynb_path: Path, links_to_download: set
) -> Tuple[str, Set[str]]:
    """
    Replace any matching image links in `line` with a relative local path from
    `ipynb_path.parent`, and add the original links to `links_to_download`.
    """
    matches = list(pc.LINK_PATTERN.finditer(line))
    if not matches:
        return line, links_to_download

    new_line = line
    for match in reversed(matches):
        old_link = match.group(1)
        links_to_download.add(old_link)

        # Local save path for the image (relative to repo root)
        local_save_path = Path(pc.IMAGE_STORAGE_PREFIX) / old_link.lstrip("/")

        # New relative path from the notebook directory to the image
        relative_link = os.path.relpath(local_save_path, ipynb_path.parent)
        relative_link_str = Path(relative_link).as_posix()

        start, end = match.span(1)
        new_line = new_line[:start] + relative_link_str + new_line[end:]
        print("  Modified image link.")

    return new_line, links_to_download


def process_notebook(ipynb_path: Path):
    """
    Processes a single Jupyter notebook file.
    Finds all matching links, downloads the images, and updates the links.
    """
    print(f"\n--- Processing Notebook: {ipynb_path} ---")

    # Read the notebook content
    try:
        with open(ipynb_path, "r", encoding="utf-8") as f:
            content_str = f.read()
            if not content_str:
                print("  [WARN] Notebook is empty. Skipping.")
                return
            nb_data = json.loads(content_str)
            indent = pc.detect_json_indent(content_str)

    except json.JSONDecodeError:
        print(f"  [ERROR] Could not parse JSON. Skipping {ipynb_path}.")
        return
    except FileNotFoundError:
        print(f"  [ERROR] File not found. Skipping {ipynb_path}.")
        return

    links_to_download: Set[str] = set()
    has_changed = False

    # Find all links and Figure blocks and update cell content
    for cell in nb_data.get("cells", []):
        if cell.get("cell_type") == "markdown":
            source_lines = cell.get(
                "source", []
            )  # 'source' is a list of strings (lines)
            new_source_lines = []

            for line in source_lines:
                if not pc.identify_cspell_directive(line):
                    new_line = pc.replace_figure_with_note(line)
                    new_line, links_to_download = replace_links(
                        new_line, ipynb_path, links_to_download
                    )
                    if new_line != line:
                        has_changed = True
                    new_source_lines.append(new_line)
                else:
                    has_changed = True
                    print("  Removed cspell directive line.")
            cell["source"] = new_source_lines

    # Download all unique images found
    if links_to_download:
        print(f"  Found {len(links_to_download)} unique images to download.")
        for link in links_to_download:
            full_url = urljoin(pc.BASE_URL, link)
            local_save_path = Path(pc.IMAGE_STORAGE_PREFIX) / link.lstrip("/")
            pc.download_image(full_url, local_save_path)
    else:
        print("  No matching image links found.")

    # Remove any cells whose `source` is empty or only blank lines before saving.
    removed_cells = 0
    filtered_cells = []
    for cell in nb_data.get("cells", []):
        src = cell.get("source", [])
        # Normalize to list of lines
        if isinstance(src, str):
            lines = src.splitlines()
        else:
            lines = list(src)

        if any(line.strip() for line in lines):
            filtered_cells.append(cell)
        else:
            removed_cells += 1

    if removed_cells:
        nb_data["cells"] = filtered_cells
        has_changed = True
        print(f"  [INFO] Removed {removed_cells} empty cells before saving.")

    # Save the notebook if it was modified
    if has_changed:
        try:
            with open(ipynb_path, "w", encoding="utf-8", newline="\n") as f:
                json.dump(nb_data, f, indent=indent, ensure_ascii=False)
            print(f"  [SUCCESS] Updated notebook: {ipynb_path}")
        except IOError as e:
            print(f"  [ERROR] Could not write updated notebook {ipynb_path}: {e}")
    else:
        print("  No changes made to notebook.")

# --- Main Execution ---

def main():
    """
    Main function to find and process all notebooks.
    """
    print("Starting IPYNB processing script...")

    for dir_name in pc.SEARCH_DIRS:
        base_path = Path(dir_name)
        if not base_path.is_dir():
            print(f"Directory not found: {base_path}. Skipping.")
            continue

        print(f"\n=== Scanning in {base_path} ===")

        # Use .rglob to recursively find all .ipynb files
        notebook_files = list(base_path.rglob("*.ipynb"))

        if not notebook_files:
            print("  No Jupyter notebooks found in this directory.")
            continue

        for ipynb_path in notebook_files:
            # Skip checkpoints
            if ".ipynb_checkpoints" in str(ipynb_path):
                continue
            process_notebook(ipynb_path)

    print("\nIPYNB processing finished.")


if __name__ == "__main__":
    main()
