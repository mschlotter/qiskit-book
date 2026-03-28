import re
from pathlib import Path

import requests

# --- Shared Configuration ---

# The base URL to prepend to the image links for downloading
BASE_URL = "https://quantum.cloud.ibm.com"

# Directories to search for files
SEARCH_DIRS = ["./myst/docs", "./myst/learning"]
#SEARCH_DIRS = ["./myst/test"]

# Image storage location prefix
IMAGE_STORAGE_PREFIX = "myst/public"

# Regex pattern to find the target links.
# This looks for "/learning/images/" or "/docs/images/" followed by
# any characters that are not a space, quote, or parenthesis.
LINK_PATTERN = re.compile(r'\]\(((?:/learning/images|/docs/images)/[^\s\'"\)]+)\)')

# --- Shared Helper Functions ---

def download_image(image_url: str, save_path: Path):
    """
    Downloads an image from a URL and saves it to a local path.
    Only downloads if the image does not exist on disk yet.
    """
    try:
        # Check if the image already exists
        if save_path.exists():
            print(f"  [SKIPPED] Already exists: {save_path}")
            return

        # Ensure the save directory exists
        save_path.parent.mkdir(parents=True, exist_ok=True)

        # Send the download request
        response = requests.get(image_url, stream=True)

        if response.status_code == 200:
            # Write the image content to the file
            with open(save_path, "wb") as f:
                f.write(response.content)
            print(f"  [SUCCESS] Downloaded: {image_url} -> {save_path}")
        else:
            print(
                f"  [ERROR] Failed to download {image_url} (Status: {response.status_code})"
            )

    except requests.exceptions.RequestException as e:
        print(f"  [ERROR] Request failed for {image_url}: {e}")
    except IOError as e:
        print(f"  [ERROR] Could not write file {save_path}: {e}")


def detect_json_indent(content_str: str) -> int:
    """
    Detects the indentation level used in a JSON file.
    Returns the number of spaces, defaulting to 2 if not detected.
    """
    for line in content_str.split("\n"):
        if line.startswith(" "):
            # Count leading spaces
            spaces = len(line) - len(line.lstrip(" "))
            if spaces > 0:
                return spaces
    return 2  # default to 2 spaces


def identify_cspell_directive(line: str) -> bool:
    """
    Identifies if the given line is a cspell directive comment.
    """
    return bool(re.match(r"^.*{\s*/\*\s*cspell:ignore.+\*/\s*\}.*", line))


def replace_figure_with_note(line: str) -> str:
    """
    Converts <Figure title="HEADING"> blocks to :::{note} HEADING blocks.
    Handles multiline content between opening and closing tags.
    """
    start_pattern = r'<Figure\s+title="([^"]+)">'
    end_pattern = r"</Figure>"

    # Check if the pattern is present in the input string
    if re.search(start_pattern, line):
        replacement = r":::{note} \1"
        new_line = re.sub(start_pattern, replacement, line)
        print("  Converted first line of Figure block to note block.")
        return new_line

    elif re.search(end_pattern, line):
        new_line = re.sub(end_pattern, ":::", line)
        print("  Converted last line of Figure block to note block.")
        return new_line

    else:
        return line
