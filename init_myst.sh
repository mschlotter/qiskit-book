#!/bin/bash

# Script to update documentation submodule, archive myst folder, and copy docs/learning/public

set -e  # Exit on error

# Default: do not update submodule, do not create archive, do not copy
UPDATE_SUBMODULE=false
CREATE_ARCHIVE=false
COPY_DOCS=false

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
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-u|--update] [-a|--archive] [-d|--docs]"
            exit 1
            ;;
    esac
done

echo "=== Step 1: Pulling latest changes from documentation submodule ==="
if [ "$UPDATE_SUBMODULE" = true ]; then
    git submodule update --remote --recursive
    echo "✓ Documentation submodule updated"
else
    echo "⊘ Skipping submodule update (use -u or --update to enable)"
fi

echo ""
echo "=== Step 2: Creating archive of myst folder ==="
if [ "$CREATE_ARCHIVE" = true ]; then
    # Generate timestamp for archive name
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    ARCHIVE_NAME="myst_${TIMESTAMP}.zip"

    # Create zip archive of myst folder
    zip -r "${ARCHIVE_NAME}" myst/ -x "*.git*"
    echo "✓ Created archive: ${ARCHIVE_NAME}"

    # Ensure archive/ directory exists
    if [ ! -d "archive" ]; then
        mkdir -p archive
        echo "✓ Created archive/ directory"
    fi

    # Move archive to archive folder
    mv "${ARCHIVE_NAME}" archive/
    echo "✓ Moved archive to archive/ folder"
else
    echo "⊘ Skipping archive creation (use -a or --archive to enable)"
fi

echo ""
echo "=== Step 3: Copying learning, and optionally docs and public folders ==="
# Ensure myst/public/ directory exists
if [ ! -d "myst/public" ]; then
    mkdir -p myst/public
    echo "✓ Created myst/public/ directory"
fi

if [ "$COPY_DOCS" = true ]; then
    # Copy docs folder
    if [ ! -d "documentation/docs" ]; then
        echo "✗ Source directory documentation/docs does not exist"
        exit 1
    fi
    
    if [ -d "myst/docs" ]; then
        echo "⚠ myst/docs/ already exists"
        read -p "Overwrite? (y/n): " overwrite_docs
        if [ "$overwrite_docs" = "y" ]; then
            cp -r documentation/docs myst/
            echo "✓ Overwrote myst/docs"
        else
            echo "⊘ Skipped myst/docs"
        fi
    else
        cp -r documentation/docs myst/
        echo "✓ Copied documentation/docs to myst/"
    fi

    # Copy public/docs folder
    if [ ! -d "documentation/public/docs" ]; then
        echo "✗ Source directory documentation/public/docs does not exist"
        exit 1
    fi
    
    if [ -d "myst/public/docs" ]; then
        echo "⚠ myst/public/docs/ already exists"
        read -p "Overwrite? (y/n): " overwrite_public_docs
        if [ "$overwrite_public_docs" = "y" ]; then
            cp -r documentation/public/docs myst/public/
            echo "✓ Overwrote myst/public/docs"
        else
            echo "⊘ Skipped myst/public/docs"
        fi
    else
        cp -r documentation/public/docs myst/public/
        echo "✓ Copied documentation/public/docs to myst/public/"
    fi
else
    echo "⊘ Skipping copy operations for docs (use -d or --docs to enable)"
fi

# Copy learning folder
if [ ! -d "documentation/learning" ]; then
    echo "✗ Source directory documentation/learning does not exist"
    exit 1
fi

if [ -d "myst/learning" ]; then
    echo "⚠ myst/learning/ already exists"
    read -p "Overwrite? (y/n): " overwrite_learning
    if [ "$overwrite_learning" = "y" ]; then
        cp -r documentation/learning myst/
        echo "✓ Overwrote myst/learning"
    else
        echo "⊘ Skipped myst/learning"
    fi
else
    cp -r documentation/learning myst/
    echo "✓ Copied documentation/learning to myst/"
fi

# Copy public/learning folder
if [ ! -d "documentation/public/learning" ]; then
    echo "✗ Source directory documentation/public/learning does not exist"
    exit 1
fi

if [ -d "myst/public/learning" ]; then
    echo "⚠ myst/public/learning/ already exists"
    read -p "Overwrite? (y/n): " overwrite_public_learning
    if [ "$overwrite_public_learning" = "y" ]; then
        cp -r documentation/public/learning myst/public/
        echo "✓ Overwrote myst/public/learning"
    else
        echo "⊘ Skipped myst/public/learning"
    fi
else
    cp -r documentation/public/learning myst/public/
    echo "✓ Copied documentation/public/learning to myst/public/"
fi

echo ""
echo "=== All operations completed successfully ==="
