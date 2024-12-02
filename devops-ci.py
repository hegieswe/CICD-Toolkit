import subprocess
import sys

# Fungsi untuk memeriksa perintah dan keluar dengan pesan error jika gagal
def check_command(command, error_message):
    try:
        subprocess.check_call(command, shell=True)
    except subprocess.CalledProcessError:
        print(f" ❌ Error: {error_message}")
        sys.exit(1)

# Fungsi untuk memeriksa login Docker
def check_docker_login():
    try:
        subprocess.check_call("docker info > /dev/null 2>&1", shell=True)
    except subprocess.CalledProcessError:
        print(" ❌ Docker tidak terdeteksi. Pastikan Docker sudah terinstall dan Anda sudah login ke Docker Hub.")
        sys.exit(1)

# Fungsi untuk membangun Docker image
def build_docker_image(image_tag):
    print("Membangun image Docker...")
    check_command(f"docker build -t {image_tag} .", "Build image Docker gagal")
    print(f"✅ Build image Docker berhasil: {image_tag}")

# Fungsi untuk menganalisis kerentanannya menggunakan Docker Scout
def analyze_vulnerabilities(image_tag):
    print("Menganalisis kerentanannya menggunakan Docker Scout...")
    check_command(f"docker scout cves {image_tag}", "Analisis kerentanannya gagal")
    print("✅ Analisis kerentanannya berhasil.")

# Fungsi untuk mendorong Docker image ke Docker Hub
def push_docker_image(image_tag):
    print("Mendorong image Docker ke Docker Hub...")
    check_command(f"docker push {image_tag}", "Push image Docker gagal")
    print(f"✅ Push image Docker berhasil ke Docker Hub: {image_tag}")

# Fungsi untuk mendapatkan nama repository dari remote Git
def get_repo_name():
    repo_url = subprocess.check_output("git config --get remote.origin.url", shell=True).decode('utf-8').strip()
    return repo_url.split('/')[-1].replace('.git', '')

# Fungsi untuk mendapatkan tag atau commit ID
def get_commit_tag():
    try:
        tag = subprocess.check_output("git describe --tags --exact-match", shell=True).decode('utf-8').strip()
        if tag:
            return tag
    except subprocess.CalledProcessError:
        pass
    commit_id = subprocess.check_output("git rev-parse --short=5 HEAD", shell=True).decode('utf-8').strip()
    return commit_id

def main():
    # Cek login Docker dan instalasi Docker
    check_docker_login()

    # Ambil nama repository dari URL remote Git
    repo_name = get_repo_name()

    # Cek tag atau commit ID untuk Docker image tag
    commit_tag = get_commit_tag()

    # Tentukan nama image Docker
    docker_username = "loyaltolpi"
    image_tag = f"{docker_username}/{repo_name}:{commit_tag}"

    # Tampilkan informasi image yang akan dibangun
    print(f"Nama image Docker: {image_tag}")

    # Proses build image Docker
    build_docker_image(image_tag)

    # Proses analisis kerentanannya
    analyze_vulnerabilities(image_tag)

    # Push image Docker ke Docker Hub
    push_docker_image(image_tag)

if __name__ == "__main__":
    main()
