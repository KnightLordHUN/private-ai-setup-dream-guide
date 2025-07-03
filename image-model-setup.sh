#!/bin/bash

# Private AI Setup Dream Guide - AI Image Generation Model Setup
# Written by Ugo Emekauwa (uemekauw@cisco.com, uemekauwa@gmail.com)
# GitHub Repository: https://github.com/ugo-emekauwa/private-ai-setup-dream-guide
# Summary: This script sets up an environment with two AI image generation models, FLUX.1 [schnell] and Stable Diffusion XL 1.0 Base.
## Stable Diffusion WebUI Forge serves as a frontend user-friendly GUI interface for interacting with the AI image generation models.

# Setup the Script Variables
echo "Setting up the Script Variables..."
set -o nounset
TARGET_HOST=127.0.0.1
SD_WEBUI_FORGE_CONTAINER_IMAGE="nykk3/stable-diffusion-webui-forge:latest"
SD_WEBUI_FORGE_CONTAINER_HOST_PORT=7860
STOP_AND_REMOVE_PREEXISTING_PRIVATE_AI_CONTAINERS=true
HUGGING_FACE_ACCESS_TOKEN=

# Start the AI Image Generation Model Setup
echo "Starting the AI Image Generation Model Setup..."

# Create the 'stable_diffusion' Folder and Sub-Folders in the $HOME Directory
echo "Creating the 'stable_diffusion' Folder and Sub-Folders in the $HOME Directory..."
mkdir -p $HOME/ai_models/stable_diffusion/outputs
mkdir -p $HOME/ai_models/stable_diffusion/models
mkdir -p $HOME/ai_models/stable_diffusion/extensions

# Update the Permissions of the 'stable_diffusion' Folder
echo "Updating the Permissions of the 'stable_diffusion' Folder..."
sudo chmod -R a+rw $HOME/ai_models/stable_diffusion

# Download the AI Image Generation Models
echo "Downloading the AI Image Generation Models..."
HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download stabilityai/stable-diffusion-xl-base-1.0 --include "sd_xl_base_1.0.safetensors" --local-dir  $HOME/ai_models/stable_diffusion/models/Stable-diffusion
HF_TOKEN=$HUGGING_FACE_ACCESS_TOKEN HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download black-forest-labs/FLUX.1-schnell --include "flux1-schnell.safetensors" --local-dir  $HOME/ai_models/stable_diffusion/models/Stable-diffusion
HF_TOKEN=$HUGGING_FACE_ACCESS_TOKEN HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download black-forest-labs/FLUX.1-schnell --include "ae.safetensors" --local-dir  $HOME/ai_models/stable_diffusion/models/VAE
HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download lllyasviel/flux_text_encoders --include "clip_l.safetensors" --local-dir  $HOME/ai_models/stable_diffusion/models/text_encoder
HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download lllyasviel/flux_text_encoders --include "t5xxl_fp16.safetensors" --local-dir  $HOME/ai_models/stable_diffusion/models/text_encoder
#HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download lllyasviel/flux_text_encoders --include "t5xxl_fp8_e4m3fn.safetensors" --local-dir  $HOME/ai_models/stable_diffusion/models/text_encoder

# Stop and Remove Preexisting Private AI Containers
if $STOP_AND_REMOVE_PREEXISTING_PRIVATE_AI_CONTAINERS; then
    echo "Stopping Preexisting Private AI Containers..."
    sudo docker stop open-webui-1 vllm-chat-model-1 vllm-chat-model-2 sglang-vision-model-1 vllm-reasoning-model-1 sd-webui-forge-1 2>/dev/null
    echo "Removing Preexisting Private AI Containers..."
    sudo docker rm open-webui-1 vllm-chat-model-1 vllm-chat-model-2 sglang-vision-model-1 vllm-reasoning-model-1 sd-webui-forge-1 2>/dev/null
fi

# Pause for clearing of the GPU vRAM
echo "Waiting for Clearing of the GPU vRAM, if Needed..."
sleep 5

# Setup the Container with Stable Diffusion WebUI Forge
echo "Setting up the Container with Stable Diffusion WebUI Forge..."
sudo docker run -d \
    --name sd-webui-forge-1 \
    -p $SD_WEBUI_FORGE_CONTAINER_HOST_PORT:7860 \
    -v $HOME/ai_models/stable_diffusion/outputs/:/app/stable-diffusion-webui/outputs/ \
    -v $HOME/ai_models/stable_diffusion/models/:/app/stable-diffusion-webui/models/ \
    -v $HOME/ai_models/stable_diffusion/extensions/:/app/stable-diffusion-webui/extensions/ \
    -e COMMANDLINE_ARGS="--theme dark --api --listen --enable-insecure-extension-access" \
    --gpus all \
    $SD_WEBUI_FORGE_CONTAINER_IMAGE
if [[ $? -eq 0 ]]; then
    sleep 5
    echo "The Container with Stable Diffusion WebUI Forge has Started..."
else
    echo "ERROR: The Container with Stable Diffusion WebUI Forge Failed to Start!"
    exit 1
fi

# Pause for the AI Image Generation Models FLUX.1 [schnell] and Stable Diffusion XL 1.0 Base to Load
echo "Waiting for the AI Image Generation Models FLUX.1 [schnell] and Stable Diffusion XL 1.0 Base to Load..."
sleep 20
echo "The Private AI Interface Will Be Available At http://$TARGET_HOST:$SD_WEBUI_FORGE_CONTAINER_HOST_PORT"

# End the AI Image Model Setup
echo "The AI Image Generation Model Setup has Completed."
