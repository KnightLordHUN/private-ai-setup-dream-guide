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
TARGET_HOST=127.0.0.1
VISION_MODEL_1_NAME="Qwen 2.5 VL, 7B"
VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE="Qwen/Qwen2.5-VL-7B-Instruct"
VISION_MODEL_1_SGLANG_FRACTION_OF_GPU_MEMORY_FOR_STATIC_ALLOCATION=0.75
VISION_MODEL_1_SGLANG_CHAT_TEMPLATE="qwen2-vl"
VISION_MODEL_1_SGLANG_CONTAINER_SHARED_MEMORY_SIZE="32g"
VISION_MODEL_1_SGLANG_MAX_CONTEXT_LENGTH=
VISION_MODEL_1_SGLANG_CONTAINER_IMAGE="lmsysorg/sglang:v0.4.6.post4-cu124"
VISION_MODEL_1_SGLANG_CONTAINER_HOST_PORT=8003
OPEN_WEBUI_CONTAINER_IMAGE="ghcr.io/open-webui/open-webui:cuda"
OPEN_WEBUI_CONTAINER_HOST_PORT=3000
OPEN_WEBUI_CONTAINER_SPECIFIC_TARGET_HOST="host.docker.internal"
STOP_AND_REMOVE_PREEXISTING_PRIVATE_AI_CONTAINERS=true
AI_MODEL_LOADING_TIMEOUT=300
HUGGING_FACE_ACCESS_TOKEN=

# Start the AI Vision Language Model Setup
echo "Starting the AI Vision Language Model Setup..."

# Create the 'ai_models' Folder in the $HOME Directory
echo "Creating the 'ai_models' Folder in the $HOME Directory..."
mkdir -p $HOME/ai_models

# Define the Hugging Face Download Local Sub-Directories
VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY="${VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE##*/}"

# Download the AI Vision Language Model
echo "Downloading the AI Vision Language Model..."
if $HUGGING_FACE_ACCESS_TOKEN; then
    HF_TOKEN=$HUGGING_FACE_ACCESS_TOKEN HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
else
    HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
fi

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

# Setup the SGLang Container with Vision Model 1 ($VISION_MODEL_1_NAME)
echo "Setting up the SGLang Container with $VISION_MODEL_1_NAME..."
if [ -z "$VISION_MODEL_1_SGLANG_MAX_CONTEXT_LENGTH" ]; then
    sudo docker run -d \
        --name sglang-vision-model-1 \
        -p $VISION_MODEL_1_SGLANG_CONTAINER_HOST_PORT:30000 \
        --gpus all \
        --shm-size $VISION_MODEL_1_SGLANG_CONTAINER_SHARED_MEMORY_SIZE \
        -v $HOME/ai_models:/models \
        --ipc=host \
        $VISION_MODEL_1_SGLANG_CONTAINER_IMAGE \
        python3 -m sglang.launch_server \
        --model-path /models/$VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY \
        --host 0.0.0.0 \
        --port 30000 \
        --served-model-name "$VISION_MODEL_1_NAME" \
        --chat-template "$VISION_MODEL_1_SGLANG_CHAT_TEMPLATE" \
        --mem-fraction-static $VISION_MODEL_1_SGLANG_FRACTION_OF_GPU_MEMORY_FOR_STATIC_ALLOCATION
else
    sudo docker run -d \
        --name sglang-vision-model-1 \
        -p $VISION_MODEL_1_SGLANG_CONTAINER_HOST_PORT:30000 \
        --gpus all \
        --shm-size $VISION_MODEL_1_SGLANG_CONTAINER_SHARED_MEMORY_SIZE \
        -v $HOME/ai_models:/models \
        --ipc=host \
        $VISION_MODEL_1_SGLANG_CONTAINER_IMAGE \
        python3 -m sglang.launch_server \
        --model-path /models/$VISION_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY \
        --host 0.0.0.0 \
        --port 30000 \
        --served-model-name "$VISION_MODEL_1_NAME" \
        --chat-template "$VISION_MODEL_1_SGLANG_CHAT_TEMPLATE" \
        --mem-fraction-static $VISION_MODEL_1_SGLANG_FRACTION_OF_GPU_MEMORY_FOR_STATIC_ALLOCATION \
        --context-length $VISION_MODEL_1_SGLANG_MAX_CONTEXT_LENGTH
fi

if [[ $? -eq 0 ]]; then
    echo "The SGLang Container with $VISION_MODEL_1_NAME has Started..."
else
    echo "ERROR: The SGLang Container with $VISION_MODEL_1_NAME Failed to Start!"
    exit 1
fi

# Wait for the AI Model to Load ($VISION_MODEL_1_NAME)
echo "The AI Model Loading Timeout is Set to $AI_MODEL_LOADING_TIMEOUT Second(s)."
echo "Waiting for $VISION_MODEL_1_NAME to Load..."

## Perform an Inference Server Health Check for the Duration of $AI_MODEL_LOADING_TIMEOUT Seconds
START_TIME=$(date +%s)
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    if [ $ELAPSED_TIME -ge $AI_MODEL_LOADING_TIMEOUT ]; then
        echo
        echo "The Timeout for Loading $VISION_MODEL_1_NAME Has Been Reached."
        echo "There May Be an Issue With the Inference Server or the Selected AI Model."
        echo "Please Check the Configuration and Try Again."
        exit 1
    fi

    if curl --silent --fail --output /dev/null "http://$TARGET_HOST:$VISION_MODEL_1_SGLANG_CONTAINER_HOST_PORT/health"; then
        echo
        echo "The AI Model $VISION_MODEL_1_NAME Has Loaded Successfully."
        break
    else
        echo -n "."
        sleep 2
    fi
done
    
# Setup the Open WebUI Container
echo "Setting up the Open WebUI Container..."
sudo docker run -d \
    --name open-webui-1 \
    -p $OPEN_WEBUI_CONTAINER_HOST_PORT:8080 \
    --gpus all \
    -e WEBUI_AUTH="false" \
    -e WEBUI_NAME="Private AI" \
    -e OPENAI_API_BASE_URLS="http://$OPEN_WEBUI_CONTAINER_SPECIFIC_TARGET_HOST:$VISION_MODEL_1_SGLANG_CONTAINER_HOST_PORT/v1" \
    -e OPENAI_API_KEY="sglang-vision-model-1-sample-key" \
    -e DEFAULT_MODELS="$VISION_MODEL_1_NAME" \
    -e RAG_EMBEDDING_MODEL="sentence-transformers/paraphrase-MiniLM-L6-v2" \
    -e ENABLE_OLLAMA_API="false" \
    --add-host=host.docker.internal:host-gateway \
    -v open-webui:/app/backend/data \
    --restart always \
    $OPEN_WEBUI_CONTAINER_IMAGE
if [[ $? -eq 0 ]]; then
    sleep 20
    echo "The Open WebUI Container has Started. The Private AI Interface Is Now Available At http://$TARGET_HOST:$OPEN_WEBUI_CONTAINER_HOST_PORT"
else
    echo "ERROR: The Open WebUI Container Failed to Start!"
    exit 1
fi

# End the AI Vision Language Model Setup
echo "The AI Vision Language Model Setup has Completed."
