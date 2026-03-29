#!/bin/bash

# Exit on error
set -e

# Default values
UPDATE_SUBMODULE=false
CREATE_ARCHIVE=false
COPY_DOCS=false
SHOW_HELP=false

# Display help text
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Script to copy and process source files for the MyST Quiskit learning
documentation. Optionally updates the Qiskit documentation submodule, creates
an archive of the myst folder, and copies docs files.

Options:
  -u | --update     Update documentation submodule (pull latest changes)
  -a | --archive    Create archive of myst folder
  -d | --docs       Copy docs and public/docs folders
  -h | --help       Display this help text and exit

Examples:
  $(basename "$0")              Copy learning folder and process files
  $(basename "$0") -u -a -d     Run all operations
  $(basename "$0") -h           Display help text and exit

EOF
}

# Step 1: Pull latest changes from documentation submodule
function update_submodule {
    echo "=== Step 1: Pulling latest changes from documentation submodule ==="
    
    if [ "$UPDATE_SUBMODULE" = true ]; then
        git submodule update --remote --recursive
        echo "[OK] Documentation submodule updated"
    else
        echo "[SKIP] Skipping submodule update (use -u or --update to enable)"
    fi
}

# Step 2: Create archive of myst folder
function create_archive {
    echo ""
    echo "=== Step 2: Creating archive of myst folder ==="
    
    if [ "$CREATE_ARCHIVE" = true ]; then
        # Generate timestamp for archive name
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        ARCHIVE_NAME="myst_${TIMESTAMP}.zip"

        # Create zip archive of myst folder
        zip -r "${ARCHIVE_NAME}" myst/ -x "*_build*"
        echo "[OK] Created archive: ${ARCHIVE_NAME}"

        # Ensure archive/ directory exists
        if [ ! -d "archive" ]; then
            mkdir -p archive
            echo "[OK] Created archive/ directory"
        fi

        # Move archive to archive folder
        mv "${ARCHIVE_NAME}" archive/
        echo "[OK] Moved archive to archive/ folder"
    else
        echo "[SKIP] Skipping archive creation (use -a or --archive to enable)"
    fi
}

# Step 3: Copy learning, docs, and public folders
function copy_folders {
    echo ""
    echo "=== Step 3: Copying learning, and optionally docs and public folders ==="
    
    # Ensure myst/public/ directory exists
    if [ ! -d "myst/public" ]; then
        mkdir -p myst/public
        echo "[OK] Created myst/public/ directory"
    fi

    if [ "$COPY_DOCS" = true ]; then
        # Copy docs folder
        if [ ! -d "documentation/docs" ]; then
            echo "[ERROR] Source directory documentation/docs does not exist"
            exit 1
        fi
        
        if [ -d "myst/docs" ]; then
            echo "[WARN] myst/docs/ already exists"
            read -p "Overwrite? (y/n): " overwrite_docs
            if [ "$overwrite_docs" = "y" ]; then
                cp -r documentation/docs myst/
                echo "[OK] Overwrote myst/docs"
            else
                echo "[SKIP] Skipped myst/docs"
            fi
        else
            cp -r documentation/docs myst/
            echo "[OK] Copied documentation/docs to myst/"
        fi

        # Copy public/docs folder
        if [ ! -d "documentation/public/docs" ]; then
            echo "[ERROR] Source directory documentation/public/docs does not exist"
            exit 1
        fi
        
        if [ -d "myst/public/docs" ]; then
            echo "[WARN] myst/public/docs/ already exists"
            read -p "Overwrite? (y/n): " overwrite_public_docs
            if [ "$overwrite_public_docs" = "y" ]; then
                cp -r documentation/public/docs myst/public/
                echo "[OK] Overwrote myst/public/docs"
            else
                echo "[SKIP] Skipped myst/public/docs"
            fi
        else
            cp -r documentation/public/docs myst/public/
            echo "[OK] Copied documentation/public/docs to myst/public/"
        fi
    else
        echo "[SKIP] Skipping copy operations for docs (use -d or --docs to enable)"
    fi

    # Copy learning folder
    if [ ! -d "documentation/learning" ]; then
        echo "[ERROR] Source directory documentation/learning does not exist"
        exit 1
    fi

    if [ -d "myst/learning" ]; then
        echo "[WARN] myst/learning/ already exists"
        read -p "Overwrite? (y/n): " overwrite_learning
        if [ "$overwrite_learning" = "y" ]; then
            cp -r documentation/learning myst/
            echo "[OK] Overwrote myst/learning"
        else
            echo "[SKIP] Skipped myst/learning"
        fi
    else
        cp -r documentation/learning myst/
        echo "[OK] Copied documentation/learning to myst/"
    fi

    # Copy public/learning folder
    if [ ! -d "documentation/public/learning" ]; then
        echo "[ERROR] Source directory documentation/public/learning does not exist"
        exit 1
    fi

    if [ -d "myst/public/learning" ]; then
        echo "[WARN] myst/public/learning/ already exists"
        read -p "Overwrite? (y/n): " overwrite_public_learning
        if [ "$overwrite_public_learning" = "y" ]; then
            cp -r documentation/public/learning myst/public/
            echo "[OK] Overwrote myst/public/learning"
        else
            echo "[SKIP] Skipped myst/public/learning"
        fi
    else
        cp -r documentation/public/learning myst/public/
        echo "[OK] Copied documentation/public/learning to myst/public/"
    fi
}

# Step 4: Process Jupyter notebooks and MDX files
function process_files {
    echo ""
    echo "=== Step 4: Processing Jupyter notebooks and MDX files ==="
    
    # Ensure myst/scripts directory exists
    if [ ! -d "myst/scripts" ]; then
        echo "[ERROR] myst/scripts/ directory does not exist"
        exit 1
    fi

    # Process Jupyter notebooks
    echo "Processing Jupyter notebooks..."
    uv run myst/scripts/process_ipynb.py
    echo "[OK] Jupyter notebooks processed"

    # Process MDX files
    echo "Processing MDX files..."
    uv run myst/scripts/process_mdx.py
    echo "[OK] MDX files processed"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--update)
            UPDATE_SUBMODULE=true
            shift
            ;;
        -a|--archive)
            CREATE_ARCHIVE=true
            shift
            ;;
        -d|--docs)
            COPY_DOCS=true
            shift
            ;;
        -h|--help)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Show help if requested
if [ "$SHOW_HELP" = true ]; then
    show_help
    exit 0
fi

# Run all steps
update_submodule
create_archive
copy_folders
process_files

echo ""
echo "=== All operations completed successfully ==="
echo ""
echo "--> Now change to the myst directory and run: uv run myst start"
