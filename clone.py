#!/usr/bin/env python3

import subprocess
import json
import logging
from pathlib import Path
import shutil  # Import shutil to remove directories
import argparse


# Setup logging for structured output with better readability
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

def check_git_installed():
    """Check if Git is installed on the system. 🚨"""
    try:
        subprocess.check_call(["git", "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        logging.info("✅ Git is installed!")
    except subprocess.CalledProcessError:
        logging.error("🚫 Git is not installed. Please install Git to proceed.")
        exit(1)

def load_credentials(auth_file):
    """Retrieve credentials from the JSON file located in the user's home directory. 🗝️"""
    if not auth_file.exists():
        logging.error(f"⚠️ Credential file not found at: {auth_file}")
        return None, None
    
    try:
        with auth_file.open("r") as file:
            creds = json.load(file)
            username = creds.get("usernameBitbucket")
            token = creds.get("tokenBitbucket")
            
            if not username or not token:
                logging.error("❌ Invalid or missing credentials in auth.json. Please check the file.")
                return None, None
            
            return username, token
    except json.JSONDecodeError:
        logging.error(f"⚠️ Error reading the JSON file: {auth_file}. Please ensure it is valid JSON.")
        return None, None

def remove_existing_directory(directory_path):
    """Remove an existing directory if it exists. 🗑️"""
    if directory_path.exists():
        logging.info(f"⛔ The directory {directory_path.name} already exists. Deleting the old directory... 🔨")
        try:
            shutil.rmtree(directory_path)  # Using shutil to remove the directory
            logging.info(f"✅ The old directory {directory_path.name} has been successfully deleted.")
        except Exception as e:
            logging.error(f"❌ Failed to delete the directory {directory_path.name}: {e}")
            return False
    return True

def clone_repository(repo_name, branch_name, username, token):
    """Clone a repository from Bitbucket. 🔄"""
    # Constructing the Bitbucket repository URL using credentials
    bitbucket_url = f"https://{username}:{token}@bitbucket.org/loyaltoid/{repo_name}.git"
    
    # Define the directory for cloning
    clone_dir = Path.cwd() / repo_name
    
    # Remove any existing directory before cloning
    if not remove_existing_directory(clone_dir):
        return

    # Log the cloning process, simulating the output from a git clone
    logging.info(f"🌟 Cloning repository '{repo_name}'... Please wait...")

    try:
        # Execute the git clone command
        subprocess.check_call(["git", "clone", "-b", branch_name, bitbucket_url, str(clone_dir)])
        
        # Log successful cloning
        logging.info(f"🎉 Repository '{repo_name}' has been successfully cloned.")
        logging.info(f"📦 Repository: {repo_name}")
        logging.info(f"🔖 Branch/Tag: {branch_name}")
        logging.info(f"📍 Location: {clone_dir}")
    except subprocess.CalledProcessError as e:
        logging.error(f"⚠️ Error occurred during cloning: {e}")

def main():
    """Main function to execute the script. 🚀"""
    # Check if Git is installed
    check_git_installed()

    # Set up argparse to accept command line arguments
    parser = argparse.ArgumentParser(description="Clone a repository from Bitbucket")
    parser.add_argument("repo_name", help="The name of the repository to clone 🔄")
    parser.add_argument("branch_name", help="The branch or tag to checkout 🔖")
    
    # Get arguments from the command line
    args = parser.parse_args()

    # Retrieve user credentials
    home_dir = Path.home()  # Using pathlib for the home directory
    auth_file = home_dir / ".devops" / "auth.json"
    
    username, token = load_credentials(auth_file)
    if not username or not token:
        logging.error("❌ Invalid credentials. Please ensure the auth.json file is correct. 🛑")
        return

    # Call the function to clone the repository
    clone_repository(args.repo_name, args.branch_name, username, token)

if __name__ == "__main__":
    main()
