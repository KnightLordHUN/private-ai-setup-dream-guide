#!/bin/bash

# Private AI Setup Dream Guide - AI Chat Model Single Setup
# Written by Ugo Emekauwa (uemekauw@cisco.com, uemekauwa@gmail.com)
# GitHub Repository: https://github.com/ugo-emekauwa/private-ai-setup-dream-guide
# Summary: This script sets up an environment with one chat LLM.
## Meta Llama 3.1 8B Instruct has been chosen as the default chat AI model.
## The choice of AI models and settings can be changed using the script variables.
## Open WebUI serves as a frontend user-friendly GUI interface for interacting with AI models.
## vLLM serves as the backend inference engine for the AI model.

# Setup the Script Variables
echo "Setting up the Script Variables..."
set -o nounset
target_host=127.0.0.1
chat_model_1_name="Meta Llama 3.1, 8B"
chat_model_1_huggingface_download_source="RedHatAI/Meta-Llama-3.1-8B-Instruct-FP8-dynamic"
chat_model_1_vllm_max_context_length=8192
chat_model_1_vllm_gpu_memory_utilization=0.9
chat_model_1_vllm_container_image="vllm/vllm-openai:v0.8.5.post1"
chat_model_1_vllm_container_host_port=8001
open_webui_container_image="ghcr.io/open-webui/open-webui:cuda"
open_webui_container_host_port=3000
open_webui_container_specific_target_host="host.docker.internal"    # If using Rootless Docker, this value may need to be changed to the actual target host IP address.
stop_and_remove_preexisting_private_ai_containers=true
ai_model_loading_timeout=300
hugging_face_access_token=

# Start the AI Chat Model Single Setup
echo "Starting the AI Chat Model Single Setup..."

# Create the 'ai_models' Folder in the $HOME Directory
echo "Creating the 'ai_models' Folder in the $HOME Directory..."
mkdir -p $HOME/ai_models

# Update the Permissions of the 'ai_models' Folder
echo "Updating the Permissions of the 'ai_models' Folder..."
sudo chmod -R a+r $HOME/ai_models

# Clear the Hugging Face Cache of Any Previously Downloaded AI Models and Files
echo "Clearing the Hugging Face Cache of Any Previously Downloaded AI Models and Files..."
for directory in $HOME/ai_models/*/.cache/huggingface/download/ $HOME/ai_models/stable_diffusion/models/*/.cache/huggingface/download/; do
	sudo rm -rf "$directory"/* 2>/dev/null
done

# Define the Hugging Face Download Local Sub-Directories
echo "Defining the Hugging Face Download Local Sub-Directories..."
chat_model_1_huggingface_download_local_sub_directory="${chat_model_1_huggingface_download_source##*/}"

# Download the AI Chat Model
echo "Downloading the AI Chat Model..."
if $hugging_face_access_token; then
    HF_TOKEN=$hugging_face_access_token HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $chat_model_1_huggingface_download_source --local-dir $HOME/ai_models/$chat_model_1_huggingface_download_local_sub_directory
else
    HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $chat_model_1_huggingface_download_source --local-dir $HOME/ai_models/$chat_model_1_huggingface_download_local_sub_directory
fi

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

# Setup the vLLM Container with Chat Model 1 ($chat_model_1_name)
echo "Setting up the vLLM Container with $chat_model_1_name..."
chat_model_1_vllm_container_args_base=(
    -d
    --name vllm-chat-model-1
    -p $chat_model_1_vllm_container_host_port:8000
    --runtime nvidia
    --gpus all
    -v $HOME/ai_models:/ai_models
    --ipc=host
    $chat_model_1_vllm_container_image
    --model /ai_models/$chat_model_1_huggingface_download_local_sub_directory
    --served-model-name "$chat_model_1_name"
    --gpu_memory_utilization=$chat_model_1_vllm_gpu_memory_utilization
)

chat_model_1_vllm_container_args_with_max_context_length=(
    "${chat_model_1_vllm_container_args_base[@]}"
    --max_model_len=$chat_model_1_vllm_max_context_length
)
chat_model_1_vllm_container_args_without_max_context_length=(
    "${chat_model_1_vllm_container_args_base[@]}"
)
if [ -z "$chat_model_1_vllm_max_context_length" ]; then
    echo "No Max Context Length Has Been Provided, the Model Default Will Be Used..."
    if docker info -f "{{println .SecurityOptions}}" 2>/dev/null | grep -q rootless; then
        docker run "${chat_model_1_vllm_container_args_without_max_context_length[@]}"
    else
        sudo docker run "${chat_model_1_vllm_container_args_without_max_context_length[@]}"
    fi
else
    echo "A Max Context Length of $chat_model_1_vllm_max_context_length Has Been Provided..."
    if docker info -f "{{println .SecurityOptions}}" 2>/dev/null | grep -q rootless; then
        docker run "${chat_model_1_vllm_container_args_with_max_context_length[@]}"
    else
        sudo docker run "${chat_model_1_vllm_container_args_with_max_context_length[@]}"
    fi
fi

if [[ $? -eq 0 ]]; then
    echo "The vLLM Container with $chat_model_1_name has Started..."
else
    echo "ERROR: The vLLM Container with $chat_model_1_name Failed to Start!"
    exit 1
fi

# Wait for the AI Model to Load ($chat_model_1_name)
echo "The AI Model Loading Timeout is Set to $ai_model_loading_timeout Second(s)."
echo "Waiting for $chat_model_1_name to Load..."

## Perform an Inference Server Health Check for the Duration of $ai_model_loading_timeout Seconds
start_time=$(date +%s)
while true; do
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    if [ $elapsed_time -ge $ai_model_loading_timeout ]; then
        echo
        echo "The Timeout for Loading $chat_model_1_name Has Been Reached."
        echo "There May Be an Issue With the Inference Server or the Selected AI Model."
        echo "Please Check the Configuration and Try Again."
        exit 1
    fi

    if curl --silent --fail --output /dev/null "http://$target_host:$chat_model_1_vllm_container_host_port/health"; then
        echo
        echo "The AI Model $chat_model_1_name Has Loaded Successfully."
        break
    else
        echo -n "."
        sleep 2
    fi
done
    
# Setup the Open WebUI Container
echo "Setting up the Open WebUI Container..."
open_webui_container_args_base=(
    -d
    --name open-webui-1
    -p $open_webui_container_host_port:8080
    --gpus all
    -e WEBUI_AUTH="false"
    -e WEBUI_NAME="Private AI"
    -e OPENAI_API_BASE_URLS="http://$open_webui_container_specific_target_host:$chat_model_1_vllm_container_host_port/v1"
    -e OPENAI_API_KEY="vllm-chat-model-1-sample-key"
    -e DEFAULT_MODELS="$chat_model_1_name"
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

# End the AI Chat Model Single Setup
echo "The AI Chat Model Single Setup has Completed."
