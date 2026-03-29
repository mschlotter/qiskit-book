# Qiskit Book

This is a proof-of-concept project to check out the capabilities of the MyST Markdown extension.
As example source, the Qiskit learning material is used and processed to be compatible with Myst. 

## Prerequisites

- **UV with Python 3.13 or higher**
- **Git** (for cloning the repository and managing submodules)
- **Node.js** (for MyST documentation building)

## Installation

### 1. Clone the Repository

Clone the repository **with its submodules** using one of the following methods:

#### Clone with Submodules

```bash
git clone --recursive https://github.com/mschlotter/qiskit-book.git
cd qiskit-book
```

This command clones the main repository and automatically initializes and updates all submodules, including the Qiskit documentation submodule.

### 2. Set Up Python Environment

Create and activate a virtual environment:

```bash
# Using uv
uv sync
```

For optional dependencies:

```bash
# Chemistry packages
uv sync --extra chem

# Cryptography packages
uv sync --extra crypto

# HPC packages
uv sync --extra hps
```

## Usage

### Initialize the MyST Documentation

The repository includes initialization scripts to set up the MyST documentation:

#### On Windows (PowerShell)

```powershell
# Basic initialization
.\init_myst.ps1
```

**Options:**
- `-update` - Update documentation submodule (pull latest changes)
- `-archive` - Create archive of myst folder
- `-docs` - Copy docs and public/docs folders
- `-help` - Display help text

#### On Unix/macOS

```bash
# Basic initialization
./init_myst.sh
```

**Options:**
- `-u` or `--update` - Update documentation submodule
- `-a` or `--archive` - Create archive of myst folder
- `-d` or `--docs` - Copy docs and public/docs folders
- `-h` or `--help` - Display help text

### Display the MyST Documentation

To generate a website, change into the myst directory and run:

```bash
uv run myst start
```

Or use the initialization scripts with the update flag (see above).

## License

This project is licensed under the MIT License.
Regarding licensing of the Qiskit submodule, see the LICENSE files in the `documentation/` submodule for details.

## Resources

- [Qiskit Documentation](https://quantum.cloud.ibm.com/docs/)
- [Qiskit Learning](https://quantum.cloud.ibm.com/learning/)
- [MyST Markdown](https://mystmd.org/)