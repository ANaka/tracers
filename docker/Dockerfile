# syntax=docker/dockerfile:1.6
FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Etc/UTC

# Install system dependencies required by diffvg, cairo-based tooling and Python build steps.
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        libxi-dev \
        libxinerama-dev \
        libxcursor-dev \
        libxrandr-dev \
        libglu1-mesa-dev \
        libgl1 \
        libglib2.0-0 \
        libcairo2 \
        libcairo2-dev \
        libpng-dev \
        ffmpeg \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Ensure `python` and `pip` binaries are available (Ubuntu defaults to python3 only).
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Prepare workspace.
WORKDIR /workspace

# Provide helper scripts inside the container image.
COPY scripts/filter_requirements.py /usr/local/bin/filter_requirements.py
RUN chmod +x /usr/local/bin/filter_requirements.py

COPY scripts/download_loras.sh /usr/local/bin/download_loras.sh
RUN chmod +x /usr/local/bin/download_loras.sh

# Install PyTorch from the official CUDA 12.1 wheels.
RUN pip install --upgrade pip setuptools wheel \
    && pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu121

# Install diffvg from source. Installing via git ensures the CUDA-enabled extension is built inside the image.
RUN pip install 'git+https://github.com/BachiLi/diffvg.git@d8038dcbe6058edbf461a775888b859504a829d6'

# Clone NeuralSVG into the image.
RUN git clone https://github.com/SagiPolaczek/NeuralSVG.git app

WORKDIR /workspace/app

# Install the remaining Python requirements without re-installing packages we already handled manually.
RUN filter_requirements.py --input requirements.txt --exclude torch torchvision torchaudio diffvg triton > /tmp/filtered-requirements.txt \
    && pip install -r /tmp/filtered-requirements.txt

# Provide an entrypoint that keeps the container ready for interactive use.
WORKDIR /workspace/app

CMD ["/bin/bash"]
