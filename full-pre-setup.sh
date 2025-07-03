#!/bin/bash

# Private AI Setup Dream Guide - Full Pre-Setup
# Written by Ugo Emekauwa (uemekauw@cisco.com, uemekauwa@gmail.com)
# Credits: lazy-electrons (rajeshvs)
# GitHub Repository: https://github.com/ugo-emekauwa/private-ai-setup-dream-guide
# Summary: This script installs the NVIDIA CUDA Toolkit, NVIDIA Driver, NVIDIA Container Toolkit, Docker, the Hugging Face Hub Python Client, and NVTOP on Ubuntu 22.04.x and related systems.
# After the software and driver installations are complete, the script then pre-downloads all of the AI models and Docker containers for the full Private AI Pre-Setup.

# Setup the Script Variables
echo "Setting up the Script Variables..."
set -o nounset
DISABLE_APPARMOR=true
DISABLE_FIREWALL=true
ENABLE_ROOTLESS_DOCKER=false
ENABLE_SYSTEM_STARTUP_FOR_ROOTLESS_DOCKER=false
CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE="RedHatAI/Meta-Llama-3.1-8B-Instruct-FP8-dynamic"
CHAT_MODEL_1_VLLM_CONTAINER_IMAGE="vllm/vllm-openai:v0.8.5.post1"
CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_SOURCE="Qwen/Qwen2.5-Coder-32B-Instruct-AWQ"
CHAT_MODEL_2_VLLM_CONTAINER_IMAGE="vllm/vllm-openai:v0.8.5.post1"
VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE="Qwen/Qwen2.5-VL-7B-Instruct"
VISION_MODEL_1_SGLANG_CONTAINER_IMAGE="lmsysorg/sglang:v0.4.6.post4-cu124"
REASONING_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE="deepseek-ai/DeepSeek-R1-Distill-Qwen-14B"
REASONING_MODEL_2_HUGGINGFACE_DOWNLOAD_SOURCE="Qwen/Qwen3-32B-AWQ"
REASONING_MODEL_1_VLLM_CONTAINER_IMAGE="vllm/vllm-openai:v0.8.5.post1"
SD_WEBUI_FORGE_CONTAINER_IMAGE="nykk3/stable-diffusion-webui-forge:latest"
OPEN_WEBUI_CONTAINER_IMAGE="ghcr.io/open-webui/open-webui:cuda"
HUGGING_FACE_ACCESS_TOKEN=

# Setup the Log File
echo "Setting up the Log File..."
mkdir -p $HOME/logs
LOG_FILE=$HOME/logs/private-ai-full-setup.log
exec > >(tee -i $LOG_FILE) 2>&1

# Start the Private AI Full Pre-Setup
echo "Starting the Private AI Full Pre-Setup..."

# Set Permissions for Accessible Private AI Setup Files
echo "Setting Permissions for Accessible Private AI Setup Files..."
SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
private_ai_files=("quick-pre-setup.sh" "chat-model-setup.sh" "chat-model-single-setup.sh" "chat-model-dual-setup.sh" "image-model-setup.sh" "vision-model-setup.sh" "reasoning-model-setup.sh" "reasoning-model-setup-alt.sh" "open-webui-only-setup.sh")
for private_ai_file in "${private_ai_files[@]}"; do
    target_file="$SCRIPT_DIRECTORY/$private_ai_file"
    [ -e "$target_file" ] && chmod a+x "$target_file"
done

# Disable AppArmor
if $DISABLE_APPARMOR; then
    echo "Disabling AppArmor..."
    sudo systemctl stop apparmor
    sudo systemctl disable apparmor
fi

# Disable Firewall
if $DISABLE_FIREWALL; then
    echo "Disabling the Firewall..."
    sudo systemctl stop ufw
    sudo systemctl disable ufw
fi

# Install the NVIDIA CUDA Toolkit
echo "Installing the NVIDIA CUDA Toolkit..."
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get install -y cuda-toolkit-12-5

# Install the NVIDIA Driver (as of 2-12-25, will also automatically install latest NVIDIA open kernel driver (nvidia-open))
if grep -qiE "(microsoft|wsl)" /proc/version; then
    echo "Microsoft WSL has been detected, skipping NVIDIA driver installation for Ubuntu, as host Windows NVIDIA driver should be used..."
else
    echo "Installing the NVIDIA Driver..."
    sudo apt-get install -y cuda-drivers-555
fi

# Uninstall Previous Docker Installations
echo "Uninstalling Previous Docker Installations..."
sudo snap remove docker --purge

# Install UIDMap (Prerequisite for Docker Rootless Mode)
if $ENABLE_ROOTLESS_DOCKER; then
    echo "Installing UIDMap (Prerequisite for Docker Rootless Mode)..."
    sudo apt-get install -y uidmap
fi

# Install Docker
echo "Installing Docker..."
curl https://get.docker.com | sh \
    && sudo systemctl --now enable docker

# Add $(whoami) to Docker Group
echo "Adding $(whoami) to Docker Group..."
sudo usermod -aG docker $(whoami)

# Setup Docker in Rootless Mode
if $ENABLE_ROOTLESS_DOCKER; then
    echo "Setting up Docker in Rootless Mode..."
    /usr/bin/dockerd-rootless-setuptool.sh install
fi

# Install the NVIDIA Container Toolkit
echo "Installing the NVIDIA Container Toolkit..."
DISTRIBUTION=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/$DISTRIBUTION/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Configure Docker to Use the NVIDIA Container Runtime
echo "Configuring Docker to Use the NVIDIA Container Runtime..."
sudo nvidia-ctk runtime configure --runtime=docker

# Ensure Any Previous NVIDIA Container Runtime Installations Are Set to Support Cgroups
echo "Ensuring Any Previous NVIDIA Container Runtime Installations Are Set to Support Cgroups..."
sudo nvidia-ctk config --set nvidia-container-cli.no-cgroups=false --in-place

# Restart Docker to Apply NVIDIA Container Runtime Configuration
echo "Restarting Docker to Apply NVIDIA Container Runtime Configuration..."
sudo systemctl restart docker

# Configure the NVIDIA Container Runtime for Docker to Run in Rootless Mode
if $ENABLE_ROOTLESS_DOCKER; then
    echo "Configuring the NVIDIA Container Runtime for Docker to Run in Rootless Mode..."
    nvidia-ctk runtime configure --runtime=docker --config=$HOME/.config/docker/daemon.json
    systemctl --user restart docker
    sudo nvidia-ctk config --set nvidia-container-cli.no-cgroups --in-place
fi

# Enable System Startup for Rootless Docker
if $ENABLE_ROOTLESS_DOCKER; then
    if $ENABLE_SYSTEM_STARTUP_FOR_ROOTLESS_DOCKER; then
        echo "Enabling System Startup for Rootless Docker..."
        systemctl --user enable docker
        sudo loginctl enable-linger $(whoami)
    fi
fi

# Install NVTOP
echo "Installing NVTOP..."
sudo add-apt-repository -y ppa:flexiondotorg/nvtop
sudo apt update
sudo apt-get install -y nvtop

# Install Python 3 pip
echo "Installing Python 3 pip..."
sudo apt-get install -y python3-pip

# Install Hugging Face Hub
echo "Installing Hugging Face Hub..."
pip3 install huggingface_hub[hf_xet]

# Install Hugging Face HF-Transfer
echo "Installing Hugging Face HF-Transfer..."
pip3 install hf_transfer

# Update PATH with Potential 'huggingface-cli' Directory
echo "Updating PATH with Potential 'huggingface-cli' Directory..."
PATH=$PATH:$HOME/.local/bin

# Add Hugging Face HF-Transfer Environment Variable to .bashrc
echo "Adding Hugging Face HF-Transfer Environment Variable to .bashrc..."
cat << EOF >> ~/.bashrc

# Hugging Face HF-Transfer Enablement
export HF_HUB_ENABLE_HF_TRANSFER=1

EOF
source ~/.bashrc

# Start the Private AI Pre-Downloads
echo "Starting the Private AI Pre-Downloads..."

# Create the 'ai_models' Folder in the $HOME Directory
echo "Creating the 'ai_models' Folder in the $HOME Directory..."
mkdir -p $HOME/ai_models

# Update the Permissions of the 'ai_models' Folder
echo "Updating the Permissions of the 'ai_models' Folder..."
sudo chmod -R a+r $HOME/ai_models

# Define the Hugging Face Download Local Sub-Directories
CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY="${CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE##*/}"
CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY="${CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_SOURCE##*/}"
VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY="${VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE##*/}"
REASONING_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY="${REASONING_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE##*/}"
REASONING_MODEL_2_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY="${REASONING_MODEL_2_HUGGINGFACE_DOWNLOAD_SOURCE##*/}"

# Download the AI Chat Models
echo "Downloading the AI Chat Models..."
if $HUGGING_FACE_ACCESS_TOKEN; then
    HF_TOKEN=$HUGGING_FACE_ACCESS_TOKEN HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
    HF_TOKEN=$HUGGING_FACE_ACCESS_TOKEN HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
else
    HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
    HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
fi

# Download the AI Vision Language Model
echo "Downloading the AI Vision Language Model..."
if $HUGGING_FACE_ACCESS_TOKEN; then
    HF_TOKEN=$HUGGING_FACE_ACCESS_TOKEN HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
else
    HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
fi

# Download the AI Reasoning Models
echo "Downloading the AI Reasoning Models..."
if $HUGGING_FACE_ACCESS_TOKEN; then
    HF_TOKEN=$HUGGING_FACE_ACCESS_TOKEN HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $REASONING_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$REASONING_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
    HF_TOKEN=$HUGGING_FACE_ACCESS_TOKEN HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $REASONING_MODEL_2_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$REASONING_MODEL_2_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
else
    HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $REASONING_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$REASONING_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
    HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $REASONING_MODEL_2_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$REASONING_MODEL_2_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
fi

# Create the 'stable_diffusion' Folder and Sub-Folders in the $HOME Directory
echo "Creating the 'stable_diffusion' Folder and Sub-Folders in the $HOME Directory..."
mkdir -p $HOME/ai_models/stable_diffusion/outputs
mkdir -p $HOME/ai_models/stable_diffusion/models
mkdir -p $HOME/ai_models/stable_diffusion/extensions

# Update the Permissions of the 'stable_diffusion' Folder
echo "Updating the Permissions of the 'stable_diffusion' Folder..."
sudo chmod -R a+w $HOME/ai_models/stable_diffusion

# Download the AI Image Generation Models
echo "Downloading the AI Image Generation Models..."
HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download stabilityai/stable-diffusion-xl-base-1.0 --include "sd_xl_base_1.0.safetensors" --local-dir  $HOME/ai_models/stable_diffusion/models/Stable-diffusion
HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download lllyasviel/flux_text_encoders --include "clip_l.safetensors" --local-dir  $HOME/ai_models/stable_diffusion/models/text_encoder
HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download lllyasviel/flux_text_encoders --include "t5xxl_fp16.safetensors" --local-dir  $HOME/ai_models/stable_diffusion/models/text_encoder
HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download lllyasviel/flux_text_encoders --include "t5xxl_fp8_e4m3fn.safetensors" --local-dir  $HOME/ai_models/stable_diffusion/models/text_encoder
HF_TOKEN=$HUGGING_FACE_ACCESS_TOKEN HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download black-forest-labs/FLUX.1-schnell --include "flux1-schnell.safetensors" --local-dir  $HOME/ai_models/stable_diffusion/models/Stable-diffusion
HF_TOKEN=$HUGGING_FACE_ACCESS_TOKEN HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download black-forest-labs/FLUX.1-schnell --include "ae.safetensors" --local-dir  $HOME/ai_models/stable_diffusion/models/VAE

# Download the vLLM Containers
echo "Downloading the vLLM Containers..."
sudo docker pull $CHAT_MODEL_1_VLLM_CONTAINER_IMAGE
sudo docker pull $CHAT_MODEL_2_VLLM_CONTAINER_IMAGE
sudo docker pull $REASONING_MODEL_1_VLLM_CONTAINER_IMAGE

# Download the SGLang Container
echo "Downloading the SGLang Container..."
sudo docker pull $VISION_MODEL_1_SGLANG_CONTAINER_IMAGE

# Download the Stable Diffusion WebUI Forge Container
echo "Downloading the Stable Diffusion WebUI Forge Container..."
sudo docker pull $SD_WEBUI_FORGE_CONTAINER_IMAGE

# Download the Open WebUI Container
echo "Downloading the Open WebUI Container..."
sudo docker pull $OPEN_WEBUI_CONTAINER_IMAGE

# End the Private AI Pre-Downloads
echo "The Private AI Pre-Downloads have Completed."

# End the Private AI Full Pre-Setup and Reboot
echo "The Private AI Full Pre-Setup has Completed."
echo "The Server will Reboot in 5 Seconds..."
sleep 5
sudo reboot
