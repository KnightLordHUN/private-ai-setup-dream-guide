#!/bin/bash

# Private AI Setup Dream Guide - Open WebUI Only Setup
# Written by Ugo Emekauwa (uemekauw@cisco.com, uemekauwa@gmail.com)
# GitHub Repository: https://github.com/ugo-emekauwa/private-ai-setup-dream-guide
# Summary: This script sets up an environment with Open WebUI only.
## Open WebUI serves as a frontend user-friendly GUI interface for interacting with AI models.

# Setup the Script Variables
echo "Setting up the Script Variables..."
set -o nounset
target_host=127.0.0.1
open_webui_default_model="Private AI Model"
open_webui_container_image="ghcr.io/open-webui/open-webui:cuda"
open_webui_container_host_port=3000
open_webui_container_specific_target_host="host.docker.internal"    # If using Rootless Docker, this value may need to be changed to the actual target host IP address.
stop_and_remove_preexisting_private_ai_containers=true

# Start the Open WebUI Only Setup
echo "Starting the Open WebUI Only Setup..."

# Stop and Remove Preexisting Private AI Containers
private_ai_containers=("open-webui-1" "vllm-chat-model-1" "vllm-chat-model-2" "sglang-vision-model-1" "vllm-reasoning-model-1" "sd-webui-forge-1")
if [ "$stop_and_remove_preexisting_private_ai_containers" = "true" ]; then
    echo "Stopping Preexisting Private AI Containers..."
    if docker info -f "{{println .SecurityOptions}}" 2>/dev/null | grep -q rootless; then
        docker stop "${private_ai_containers[@]}" 2>/dev/null
    else
        sudo docker stop "${private_ai_containers[@]}" 2>/dev/null
    fi

    echo "Removing Preexisting Private AI Containers..."
    if docker info -f "{{println .SecurityOptions}}" 2>/dev/null | grep -q rootless; then
        docker rm "${private_ai_containers[@]}" 2>/dev/null
    else
        sudo docker rm "${private_ai_containers[@]}" 2>/dev/null
    fi
fi

# Pause for clearing of the GPU vRAM
echo "Waiting for Clearing of the GPU vRAM, if Needed..."
sleep 5

# Setup the Open WebUI Container
echo "Setting up the Open WebUI Container..."
open_webui_container_args_base=(
    -d
    --name open-webui-1
    -p $open_webui_container_host_port:8080
    --gpus all
    -e WEBUI_AUTH="false"
    -e WEBUI_NAME="Private AI"
    -e OPENAI_API_BASE_URLS=""
    -e OPENAI_API_KEY=""
    -e DEFAULT_MODELS="$open_webui_default_model"
    -e RAG_EMBEDDING_MODEL="sentence-transformers/paraphrase-MiniLM-L6-v2"
    -e ENABLE_OLLAMA_API="false"
    --add-host=host.docker.internal:host-gateway
    -v open-webui:/app/backend/data
    --restart always
    $open_webui_container_image
)
if docker info -f "{{println .SecurityOptions}}" 2>/dev/null | grep -q rootless; then
    docker run "${open_webui_container_args_base[@]}"
else
    sudo docker run "${open_webui_container_args_base[@]}"
fi

if [[ $? -eq 0 ]]; then
    sleep 20
    echo "The Open WebUI Container has Started. The Private AI Interface Is Now Available At http://$target_host:$open_webui_container_host_port"
else
    echo "ERROR: The Open WebUI Container Failed to Start!"
    exit 1
fi

# End the Open WebUI Only Setup
echo "The Open WebUI Only Setup has Completed."
