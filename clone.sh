#!/bin/bash

# Path ke file JSON yang berisi username dan token
AUTH_FILE="$HOME/.devops/auth.json"

# Fungsi untuk memeriksa apakah sebuah file ada
check_file_exists() {
    if [ ! -f "$1" ]; then
        echo "Error: File $1 tidak ditemukan."
        exit 1
    fi
}

# Fungsi untuk memeriksa apakah jq terinstal
check_jq_installed() {
    if ! which jq > /dev/null 2>&1; then
        echo "Error: jq tidak terinstal. Instal jq terlebih dahulu."
        exit 1
    fi
}

# Fungsi untuk memvalidasi input pengguna (direktori dan branch/tag)
validate_input() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Error: Nama folder tujuan dan branch/tag harus diberikan."
        echo "Usage: $0 <repository_name> <branch_or_tag>"
        exit 1
    fi
}

# Fungsi untuk mengambil username dan token dari file JSON
get_credentials() {
    USERNAME=$(jq -r '.usernameBitbucket' "$1")
    TOKEN=$(jq -r '.tokenBitbucket' "$1")

    if [ -z "$USERNAME" ] || [ -z "$TOKEN" ]; then
        echo "Error: Username atau token tidak ditemukan di $1."
        exit 1
    fi
}

# Fungsi untuk menghapus direktori jika sudah ada
remove_existing_directory() {
    if [ -d "$1" ]; then
        echo "The directory $1 already exists, deleting the old directory."
        rm -rf "$1" || { echo "Failed to delete the old directory."; exit 1; }
        echo "The old directory $1 has been successfully deleted."
    fi
}

# Fungsi untuk meng-clone repository
clone_repository() {
    AUTH_URL="https://${USERNAME}:${TOKEN}@bitbucket.org/loyaltoid/$1.git"
    if git clone --branch "$2" "$AUTH_URL" "$1"; then
        echo "The repository has been successfully cloned."
        echo "Repository: $1"
        echo "Branch/Tag: $2"
        echo "Location: $(pwd)/$1"
    else
        echo "Failed to clone the repository."
        exit 1
    fi
}

# ---- MAIN SCRIPT ----

# Validasi input
DEST_DIR="$1"
BRANCH_OR_TAG="$2"
validate_input "$DEST_DIR" "$BRANCH_OR_TAG"

# Periksa apakah file autentikasi ada
check_file_exists "$AUTH_FILE"

# Periksa apakah jq terinstal
check_jq_installed

# Ambil kredensial (username dan token) dari file autentikasi
get_credentials "$AUTH_FILE"

# Hapus direktori yang sudah ada jika diperlukan
remove_existing_directory "$DEST_DIR"

# Clone repository
clone_repository "$DEST_DIR" "$BRANCH_OR_TAG"
