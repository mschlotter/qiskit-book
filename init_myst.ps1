#!/usr/bin/env pwsh

# Script parameters
param(
    [switch]$Update,
    [switch]$Archive,
    [switch]$Docs,
    [switch]$Help
)

# Exit on error
$ErrorActionPreference = "Stop"

# Map parameters to script variables
$UPDATE_SUBMODULE = $Update.IsPresent
$CREATE_ARCHIVE = $Archive.IsPresent
$COPY_DOCS = $Docs.IsPresent
$SHOW_HELP = $Help.IsPresent

# Get script name for help display (without extension)
$SCRIPT_NAME = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)

# Display help text
function Show-Help {
    param([string]$ScriptName)
    @"
Usage: $ScriptName [OPTIONS]

Script to copy and process source files for the MyST Quiskit learning
documentation. Optionally updates the Qiskit documentation submodule, creates
an archive of the myst folder, and copies docs files.

Options:
  -update      Update documentation submodule (pull latest changes)
  -archive     Create archive of myst folder
  -docs        Copy docs and public/docs folders
  -help        Display this help text and exit

Examples:
  $ScriptName                         Copy learning folder and process files
  $ScriptName -update -archive -docs  Run all operations
  $ScriptName -help                   Display this help text and exit

"@
}

# Step 1: Pull latest changes from documentation submodule
function Update-Submodule {
    Write-Host "== Step 1: Pulling latest changes from documentation submodule =="

    if ($UPDATE_SUBMODULE) {
        git submodule update --remote --recursive
        Write-Host "[OK] Documentation submodule updated"
    } else {
        Write-Host "[SKIP] Skipping submodule update (use -u or --update to enable)"
    }
}

# Step 2: Create archive of myst folder
function Create-Archive {
    Write-Host ""
    Write-Host "== Step 2: Creating archive of myst folder =="

    if ($CREATE_ARCHIVE) {
        # Generate timestamp for archive name
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $archiveName = "myst_${timestamp}.zip"

        # Create zip archive of myst folder, excluding _build directories
        $tempDir = "myst_archive_temp"
        
        # Remove temp directory if it exists
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
        }
        
        # Create temp directory
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        
        # Copy myst folder excluding _build directories
        Copy-Item -Path "myst" -Destination $tempDir -Recurse -Force
        
        # Find and remove all _build directories recursively
        $buildDirs = Get-ChildItem -Path "$tempDir\myst" -Filter "_build" -Directory -Recurse
        foreach ($dir in $buildDirs) {
            Remove-Item -Path $dir.FullName -Recurse -Force
        }
        
        # Create zip archive
        $params = @{
            Path = "$tempDir\myst"
            DestinationPath = $archiveName
            CompressionLevel = "Optimal"
        }
        Compress-Archive @params -Force
        Write-Host "[OK] Created archive: $archiveName"
        
        # Clean up temp directory
        Remove-Item -Path $tempDir -Recurse -Force

        # Ensure archive/ directory exists
        if (-not (Test-Path "archive")) {
            New-Item -ItemType Directory -Path "archive" | Out-Null
            Write-Host "[OK] Created archive/ directory"
        }

        # Move archive to archive folder
        Move-Item -Path $archiveName -Destination "archive\"
        Write-Host "[OK] Moved archive to archive/ folder"
    } else {
        Write-Host "[SKIP] Skipping archive creation (use -a or --archive to enable)"
    }
}

# Step 3: Copy learning, docs, and public folders
function Copy-Folders {
    Write-Host ""
    Write-Host "== Step 3: Copying learning, and optionally docs folders =="

    # Ensure myst/public/ directory exists
    if (-not (Test-Path "myst\public")) {
        New-Item -ItemType Directory -Path "myst\public" | Out-Null
        Write-Host "[OK] Created myst/public/ directory"
    }

    if ($COPY_DOCS) {
        # Copy docs folder
        if (-not (Test-Path "documentation\docs")) {
            Write-Host "[ERROR] Source directory documentation\docs does not exist"
            exit 1
        }
        
        if (Test-Path "myst\docs") {
            Write-Host "[WARN] myst/docs/ already exists"
            $overwrite = Read-Host "Overwrite? (y/n)"
            if ($overwrite -eq "y") {
                Remove-Item -Path "myst\docs" -Recurse -Force
                Copy-Item -Path "documentation\docs" -Destination "myst\docs" -Recurse
                Write-Host "[OK] Overwrote myst/docs"
            } else {
                Write-Host "[SKIP] Skipped myst/docs"
            }
        } else {
            Copy-Item -Path "documentation\docs" -Destination "myst\docs" -Recurse
            Write-Host "[OK] Copied documentation/docs to myst/"
        }

        # Copy public/docs folder
        if (-not (Test-Path "documentation\public\docs")) {
            Write-Host "[ERROR] Source directory documentation\public\docs does not exist"
            exit 1
        }
        
        if (Test-Path "myst\public\docs") {
            Write-Host "[WARN] myst/public/docs/ already exists"
            $overwrite = Read-Host "Overwrite? (y/n)"
            if ($overwrite -eq "y") {
                Remove-Item -Path "myst\public\docs" -Recurse -Force
                Copy-Item -Path "documentation\public\docs" -Destination "myst\public\docs" -Recurse
                Write-Host "[OK] Overwrote myst/public/docs"
            } else {
                Write-Host "[SKIP] Skipped myst/public/docs"
            }
        } else {
            Copy-Item -Path "documentation\public\docs" -Destination "myst\public\docs" -Recurse
            Write-Host "[OK] Copied documentation/public/docs to myst/public/"
        }
    } else {
        Write-Host "[SKIP] Skipping copy operations for docs (use -d or --docs to enable)"
    }

    # Copy learning folder
    if (-not (Test-Path "documentation\learning")) {
        Write-Host "[ERROR] Source directory documentation\learning does not exist"
        exit 1
    }

    if (Test-Path "myst\learning") {
        Write-Host "[WARN] myst/learning/ already exists"
        $overwrite = Read-Host "Overwrite? (y/n)"
        if ($overwrite -eq "y") {
            Remove-Item -Path "myst\learning" -Recurse -Force
            Copy-Item -Path "documentation\learning" -Destination "myst\learning" -Recurse
            Write-Host "[OK] Overwrote myst/learning"
        } else {
            Write-Host "[SKIP] Skipped myst/learning"
        }
    } else {
        Copy-Item -Path "documentation\learning" -Destination "myst\learning" -Recurse
        Write-Host "[OK] Copied documentation/learning to myst/"
    }

    # Copy public/learning folder
    if (-not (Test-Path "documentation\public\learning")) {
        Write-Host "[ERROR] Source directory documentation\public\learning does not exist"
        exit 1
    }

    if (Test-Path "myst\public\learning") {
        Write-Host "[WARN] myst/public/learning/ already exists"
        $overwrite = Read-Host "Overwrite? (y/n)"
        if ($overwrite -eq "y") {
            Remove-Item -Path "myst\public\learning" -Recurse -Force
            Copy-Item -Path "documentation\public\learning" -Destination "myst\public\learning" -Recurse
            Write-Host "[OK] Overwrote myst/public/learning"
        } else {
            Write-Host "[SKIP] Skipped myst/public/learning"
        }
    } else {
        Copy-Item -Path "documentation\public\learning" -Destination "myst\public\learning" -Recurse
        Write-Host "[OK] Copied documentation/public/learning to myst/public/"
    }
}

# Step 4: Process Jupyter notebooks and MDX files
function Process-Files {
    Write-Host ""
    Write-Host "== Step 4: Processing Jupyter notebooks and MDX files =="

    # Ensure myst/scripts directory exists
    if (-not (Test-Path "myst\scripts")) {
        Write-Host "[ERROR] myst/scripts/ directory does not exist"
        exit 1
    }

    # Process Jupyter notebooks
    Write-Host "Processing Jupyter notebooks..."
    uv run myst/scripts/process_ipynb.py
    Write-Host "[OK] Jupyter notebooks processed"

    # Process MDX files
    Write-Host "Processing MDX files..."
    uv run myst/scripts/process_mdx.py
    Write-Host "[OK] MDX files processed"
}

# Show help if requested
if ($SHOW_HELP) {
    Show-Help $SCRIPT_NAME
    exit 0
}

# Run all steps
Update-Submodule
Create-Archive
Copy-Folders
Process-Files

Write-Host ""
Write-Host "== All operations completed successfully =="
Write-Host ""
Write-Host "--> Now change to the myst directory and run: uv run myst start"
