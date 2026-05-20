import os
import re
from pathlib import Path
from typing import Set, Tuple
from urllib.parse import urljoin

import process_config as pc

# --- Helper Functions ---

def replace_links(content: str, mdx_path: Path) -> Tuple[str, Set[str]]:
    """
    Replace remote image links in `content` with relative local paths from `mdx_path.parent`,
    and return the new content plus a set of image link paths that need downloading.
    """
    links_to_download: Set[str] = set()

    def _repl(match: re.Match) -> str:
        old_link = match.group(1)
        links_to_download.add(old_link)

        local_save_path = Path(pc.IMAGE_STORAGE_PREFIX) / old_link.lstrip("/")
        relative_link = os.path.relpath(local_save_path, mdx_path.parent)
        relative_link_str = Path(relative_link).as_posix()
        return f"]({relative_link_str})"

    new_content = pc.LINK_PATTERN.sub(_repl, content)
    return new_content, links_to_download


def process_markup(mdx_path: Path):
    print(f"\n--- Processing MDX: {mdx_path} ---")

    # Read the MDX content
    try:
        content = mdx_path.read_text(encoding="utf-8")
    except Exception as e:
        print(f"  [ERROR] Could not read {mdx_path}: {e}")
        return

    # Replace links and collect those to download
    new_content, links_to_download = replace_links(content, mdx_path)

    # Remove the "## Exam" section and everything that follows
    exam_match = re.search(r"(?m)^\s*##\s*Exam\b", new_content)
    if exam_match:
        new_content = new_content[: exam_match.start()].rstrip() + "\n"
        print("  [INFO] Removed '## Exam' section and following content.")

    # Download all unique images found
    if links_to_download:
        print(f"  Found {len(links_to_download)} unique images to download.")
        for link in links_to_download:
            full_url = urljoin(pc.BASE_URL, link)
            local_save_path = Path(pc.IMAGE_STORAGE_PREFIX) / link.lstrip("/")
            pc.download_image(full_url, local_save_path)
    else:
        print("  No matching image links found.")

    # Save the modified MDX content to a .md file
    md_path = mdx_path.with_suffix(".md")
    try:
        md_path.write_text(new_content, encoding="utf-8", newline="\n")
        print(f"  [SUCCESS] Wrote converted file: {md_path}")
    except Exception as e:
        print(f"  [ERROR] Could not write {md_path}: {e}")

# --- Main Execution ---

def main():
    """
    Main function to find and process all markdown files.
    """
    print("Starting MDX processing script...")

    for dir_name in pc.SEARCH_DIRS:
        base_path = Path(dir_name)
        if not base_path.is_dir():
            print(f"Directory not found: {base_path}. Skipping.")
            continue

        print(f"\n=== Scanning in {base_path} ===")

        # Use .rglob to recursively find all .mdx files
        mdx_files = list(base_path.rglob("*.mdx"))

        if not mdx_files:
            print(f"  No .mdx files found in {base_path}.")
            continue

        for mdx_path in mdx_files:
            process_markup(mdx_path)

    print("\nMDX processing finished.")


if __name__ == "__main__":
    main()
