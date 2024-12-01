#!/usr/bin/env bash

# Cek apakah Docker sudah terinstall dan apakah kita sudah login ke Docker Hub
# Jika Docker tidak terdeteksi, tampilkan pesan error dan keluar
if ! docker info > /dev/null 2>&1; then
    echo " ❌ Docker tidak terdeteksi. Pastikan Docker sudah terinstall dan Anda sudah login ke Docker Hub."
    exit 1
fi

# Ambil nama repository dari URL remote Git. 
# Misalnya, jika URL git remote adalah https://github.com/loyaltolpi/my-app.git, 
# maka nama repository yang diambil adalah "my-app"
REPO_NAME=$(basename -s .git `git config --get remote.origin.url`)

# Cek apakah commit git saat ini memiliki tag.
# Perintah `git describe --tags --exact-match` akan mengembalikan tag jika commit saat ini memiliki tag.
# Jika tidak ada tag, perintah ini akan menghasilkan output kosong.
TAG=$(git describe --tags --exact-match 2>/dev/null)

# Jika ada tag, gunakan tag tersebut sebagai tag Docker image.
# Jika tidak ada tag, ambil commit ID yang pendek (5 digit) untuk menjadi tag image Docker.
if [ -n "$TAG" ]; then
    # Jika ada tag, gunakan tag sebagai Docker image tag
    COMMIT_TAG="$TAG"
else
    # Jika tidak ada tag, ambil commit ID dan hanya gunakan 5 digit pertama dari ID commit
    COMMIT_TAG=$(git rev-parse --short=5 HEAD)
fi

# Gabungkan nama pengguna Docker Hub dan nama repository untuk membuat tag Docker yang lengkap
# Format tag image Docker adalah: <dockerhub-username>/<repository-name>:<commit-id-or-tag>
IMAGE_TAG="loyaltolpi/${REPO_NAME}:${COMMIT_TAG}"

# Menampilkan informasi tentang nama image dan tag yang akan dibangun
echo "Nama image Docker: ${IMAGE_TAG}"

# Proses build Docker image menggunakan Dockerfile yang ada di repositori saat ini
echo "Membangun image Docker..."
docker build -t ${IMAGE_TAG} .

# Mengecek apakah proses build image Docker berhasil
if [ $? -eq 0 ]; then
    echo "✅ Build image Docker berhasil: ${IMAGE_TAG}"
else
    # Jika build gagal, tampilkan pesan error dan keluar dengan status 1
    echo "❌ Build image Docker gagal."
    exit 1
fi

# Menjalankan analisis kerentanannya menggunakan Docker Scout
# Docker Scout membantu untuk memeriksa apakah ada kerentanannya dalam image yang telah dibangun.
echo "Menganalisis kerentanannya menggunakan Docker Scout..."
docker scout cves ${IMAGE_TAG}

# Mengecek apakah analisis kerentanannya berhasil
if [ $? -eq 0 ]; then
    # Jika analisis kerentanannya berhasil, tampilkan pesan sukses
    echo "✅ Analisis kerentanannya berhasil."
else
    # Jika ada kesalahan saat analisis, tampilkan pesan error dan keluar dengan status 1
    echo "❌ Terjadi kesalahan saat melakukan analisis kerentanannya."
    exit 1
fi

# Mendorong (push) Docker image yang telah dibangun ke Docker Hub
echo "Mendorong image Docker ke Docker Hub..."
docker push ${IMAGE_TAG}

# Mengecek apakah proses push image ke Docker Hub berhasil
if [ $? -eq 0 ]; then
    # Jika push berhasil, tampilkan pesan sukses
    echo "✅ Push image Docker berhasil ke Docker Hub: ${IMAGE_TAG}"
else
    # Jika push gagal, tampilkan pesan error dan keluar dengan status 1
    echo "❌ Push image Docker gagal."
    exit 1
fi
