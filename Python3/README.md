# 🚀 Git Clone Helper (`cl`)

An efficient, beautiful, and robust Python script to streamline your `git clone` workflow.

## Features
- **Smart Defaults**: Clones from your configured Git host (default: `bitbucket.org`) and workspace (default: `loyaltoid`).
- **Visual Feedback**: Clean, rounded UI with dynamic resizing and progress spinners.
- **Safety**: Automatically handles existing directories (auto-replace) to keep your flow uninterrupted.
- **Efficiency**: Supports **Single Branch** cloning to save time and disk space.
- **Configurable**: Customize behavior via CLI arguments or Environment Variables.

## Usage

```bash
# Basic usage (defaults to Full Clone from Develop/Main usually)
cl <repo-name>

# Specific branch/tag
cl <repo-name> <branch-or-tag>

# Single Branch Mode (Faster, fetches only the specific branch history)
cl <repo-name> <branch> -s

# Shallow Clone (Depth N)
cl <repo-name> -d 1
```

### Options

| Flag | Long Flag | Description |
| :--- | :--- | :--- |
| `-s` | `--single` | **Single Branch Clone**. Only fetches history for the specified branch. |
| `-d` | `--depth` | **Shallow Clone**. Truncate history to the specified number of commits. |
| `-f` | `--force` | Force remove existing directory (implied by default in this version). |
| `-w` | `--workspace` | Override workspace (e.g. `my-org`). Default: `loyaltoid`. |
| | `--host` | Override Git Host. Default: `bitbucket.org`. |

## Examples

**1. Standard Clone**
```bash
cl saas-apigateway
```

**2. Clone specific branch 'feature/login'**
```bash
cl saas-apigateway feature/login
```

**3. Efficient Single Branch Clone (Recommended for quick checks)**
```bash
cl saas-apigateway develop -s
```

## Configuration (Environment Variables)

You can set these in your `.bashrc` or `.zshrc` to override defaults permanently:

```bash
export CL_WORKSPACE="my-team"
export CL_GIT_HOST="github.com"
```

## Requirements
- Python 3
- Git installed and accessible via `git` command.
- SSH Key configured for your Git Host (the script uses `git@...` SSH URLs).
