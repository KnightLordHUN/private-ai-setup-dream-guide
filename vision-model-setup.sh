#!/bin/bash

# Private AI Setup Dream Guide - AI Vision Language Model Setup
# Written by Ugo Emekauwa (uemekauw@cisco.com, uemekauwa@gmail.com)
# GitHub Repository: https://github.com/ugo-emekauwa/private-ai-setup-dream-guide
# Summary: This script sets up an environment with one vision language model.
## Qwen 2.5 VL 7B Instruct has been chosen as the default vision AI model.
## The choice of AI models and settings can be changed using the script variables.
## Open WebUI serves as a frontend user-friendly GUI interface for interacting with AI models.
## SGLang serves as the backend inference engine for the AI model.

# Setup the Script Variables
echo "Setting up the Script Variables..."
set -o nounset
target_host=127.0.0.1
vision_model_1_name="Qwen 2.5 VL, 7B"
vision_model_1_huggingface_download_source="Qwen/Qwen2.5-VL-7B-Instruct"
vision_model_1_sglang_fraction_of_gpu_memory_for_static_allocation=0.75
vision_model_1_sglang_chat_template="qwen2-vl"
vision_model_1_sglang_container_shared_memory_size="32g"
vision_model_1_sglang_max_context_length=
vision_model_1_sglang_container_image="lmsysorg/sglang:v0.4.6.post4-cu124"
vision_model_1_sglang_container_host_port=8003
open_webui_container_image="ghcr.io/open-webui/open-webui:cuda"
open_webui_container_host_port=3000
open_webui_container_specific_target_host="host.docker.internal"    # If using Rootless Docker, this value may need to be changed to the actual target host IP address.
stop_and_remove_preexisting_private_ai_containers=true
ai_model_loading_timeout=300
hugging_face_access_token=

# Start the AI Vision Language Model Setup
echo "Starting the AI Vision Language Model Setup..."

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
vision_model_1_huggingface_download_local_sub_directory="${vision_model_1_huggingface_download_source##*/}"

# Download the AI Vision Language Model
echo "Downloading the AI Vision Language Model..."
if $hugging_face_access_token; then
    HF_TOKEN=$hugging_face_access_token HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $vision_model_1_huggingface_download_source --local-dir $HOME/ai_models/$vision_model_1_huggingface_download_local_sub_directory
else
    HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $vision_model_1_huggingface_download_source --local-dir $HOME/ai_models/$vision_model_1_huggingface_download_local_sub_directory
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

# Setup the SGLang Container with Vision Model 1 ($vision_model_1_name)
echo "Setting up the SGLang Container with $vision_model_1_name..."
vision_model_1_sglang_container_args_base=(
    -d
    --name sglang-vision-model-1
    -p $vision_model_1_sglang_container_host_port:30000
    --gpus all
    --shm-size $vision_model_1_sglang_container_shared_memory_size
    -v $HOME/ai_models:/models
    --ipc=host
    $vision_model_1_sglang_container_image
    python3 -m sglang.launch_server
    --model-path /models/$vision_model_1_huggingface_download_local_sub_directory
    --host 0.0.0.0
    --port 30000
    --served-model-name "$vision_model_1_name"
    --chat-template "$vision_model_1_sglang_chat_template"
    --mem-fraction-static $vision_model_1_sglang_fraction_of_gpu_memory_for_static_allocation
)

vision_model_1_sglang_container_args_with_max_context_length=(
    "${vision_model_1_sglang_container_args_base[@]}"
    --context-length $vision_model_1_sglang_max_context_length
)
vision_model_1_sglang_container_args_without_max_context_length=(
    "${vision_model_1_sglang_container_args_base[@]}"
)
if [ -z "$vision_model_1_sglang_max_context_length" ]; then
    echo "No Max Context Length Has Been Provided, the Model Default Will Be Used..."
    if docker info -f "{{println .SecurityOptions}}" 2>/dev/null | grep -q rootless; then
        docker run "${vision_model_1_sglang_container_args_without_max_context_length[@]}"
    else
        sudo docker run "${vision_model_1_sglang_container_args_without_max_context_length[@]}"
    fi
else
    echo "A Max Context Length of $vision_model_1_sglang_max_context_length Has Been Provided..."
    if docker info -f "{{println .SecurityOptions}}" 2>/dev/null | grep -q rootless; then
        docker run "${vision_model_1_sglang_container_args_with_max_context_length[@]}"
    else
        sudo docker run "${vision_model_1_sglang_container_args_with_max_context_length[@]}"
    fi
fi

if [[ $? -eq 0 ]]; then
    echo "The SGLang Container with $vision_model_1_name has Started..."
else
    echo "ERROR: The SGLang Container with $vision_model_1_name Failed to Start!"
    exit 1
fi

# Wait for the AI Model to Load ($vision_model_1_name)
echo "The AI Model Loading Timeout is Set to $ai_model_loading_timeout Second(s)."
echo "Waiting for $vision_model_1_name to Load..."

## Perform an Inference Server Health Check for the Duration of $ai_model_loading_timeout Seconds
start_time=$(date +%s)
while true; do
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    if [ $elapsed_time -ge $ai_model_loading_timeout ]; then
        echo
        echo "The Timeout for Loading $vision_model_1_name Has Been Reached."
        echo "There May Be an Issue With the Inference Server or the Selected AI Model."
        echo "Please Check the Configuration and Try Again."
        exit 1
    fi

    if curl --silent --fail --output /dev/null "http://$target_host:$vision_model_1_sglang_container_host_port/health"; then
        echo
        echo "The AI Model $vision_model_1_name Has Loaded Successfully."
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
    -e OPENAI_API_BASE_URLS="http://$open_webui_container_specific_target_host:$vision_model_1_sglang_container_host_port/v1"
    -e OPENAI_API_KEY="sglang-vision-model-1-sample-key"
    -e DEFAULT_MODELS="$vision_model_1_name"
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

# End the AI Vision Language Model Setup
echo "The AI Vision Language Model Setup has Completed."
