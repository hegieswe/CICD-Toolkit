#!/usr/bin/env python3

import subprocess
import json
import logging
from pathlib import Path
import shutil  # Import shutil untuk menghapus direktori
import argparse


# Setup logging untuk output yang lebih terstruktur
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

def check_git_installed():
    """Memeriksa apakah Git sudah terinstal di sistem."""
    try:
        subprocess.check_call(["git", "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError:
        logging.error("Git tidak ditemukan. Pastikan Git telah terinstal di sistem Anda.")
        exit(1)

def load_credentials(auth_file):
    """Mengambil kredensial dari file JSON yang ada di direktori home pengguna."""
    if not auth_file.exists():
        logging.error(f"File kredensial tidak ditemukan di: {auth_file}")
        return None, None
    
    try:
        with auth_file.open("r") as file:
            creds = json.load(file)
            return creds.get("usernameBitbucket"), creds.get("tokenBitbucket")
    except json.JSONDecodeError:
        logging.error(f"Terjadi kesalahan dalam membaca file JSON: {auth_file}")
        return None, None

def clone_repository(repo_name, branch_name, username, token):
    """Melakukan cloning repository dari Bitbucket."""
    # Menentukan URL repository Bitbucket menggunakan kredensial
    bitbucket_url = f"https://{username}:{token}@bitbucket.org/loyaltoid/{repo_name}.git"
    
    # Menentukan direktori tempat cloning
    clone_dir = Path.cwd() / repo_name
    
    # Periksa apakah folder dengan nama repo sudah ada, hapus jika perlu
    if clone_dir.exists():
        logging.warning(f"Direktori {repo_name} sudah ada. Menghapus direktori lama...")
        try:
            shutil.rmtree(clone_dir)  # Menggunakan shutil untuk menghapus direktori
            logging.info(f"Direktori {repo_name} berhasil dihapus.")
        except Exception as e:
            logging.error(f"Gagal menghapus direktori {repo_name}: {e}")
            return

    # Clone repository
    try:
        logging.info(f"Cloning repository {repo_name} dari branch {branch_name}...")
        subprocess.check_call(["git", "clone", "-b", branch_name, bitbucket_url, str(clone_dir)])
        logging.info(f"Repository {repo_name} berhasil di-clone ke {clone_dir}.")
    except subprocess.CalledProcessError as e:
        logging.error(f"Terjadi kesalahan saat cloning: {e}")

def main():
    """Fungsi utama untuk menjalankan script."""
    # Memeriksa apakah git terinstal
    check_git_installed()

    # Mengatur parser untuk menerima argumen dari command line
    parser = argparse.ArgumentParser(description="Clone repository dari Bitbucket")
    parser.add_argument("repo_name", help="Nama repository yang akan di-clone")
    parser.add_argument("branch_name", help="Nama branch yang akan di-checkout")
    
    # Mendapatkan argumen dari command line
    args = parser.parse_args()

    # Mendapatkan kredensial pengguna
    home_dir = Path.home()  # Menggunakan pathlib untuk direktori home
    auth_file = home_dir / ".devops" / "auth.json"
    
    username, token = load_credentials(auth_file)
    if not username or not token:
        logging.error("Kredensial tidak valid, pastikan file auth.json sudah benar.")
        return

    # Panggil fungsi cloning repository
    clone_repository(args.repo_name, args.branch_name, username, token)

if __name__ == "__main__":
    main()
