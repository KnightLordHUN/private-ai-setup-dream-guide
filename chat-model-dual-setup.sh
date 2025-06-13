#!/bin/bash

# Private AI Setup Dream Guide - AI Chat Model Dual Setup
# Written by Ugo Emekauwa (uemekauw@cisco.com, uemekauwa@gmail.com)
# GitHub Repository: https://github.com/ugo-emekauwa/private-ai-setup-dream-guide
# Summary: This script sets up an environment with two chat LLMs.
## Meta Llama 3.1 8B Instruct and Qwen 2.5 Coder 32B Instruct have been chosen as the default chat AI models.
## The choice of AI models and settings can be changed using the script variables.
## Open WebUI serves as a frontend user-friendly GUI interface for interacting with AI models.
## vLLM serves as the backend inference engine for the AI models.

# Setup the Script Variables
echo "Setting up the Script Variables..."
set -o nounset
CHAT_MODEL_1_NAME="Meta Llama 3.1, 8B"
CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE="RedHatAI/Meta-Llama-3.1-8B-Instruct-FP8-dynamic"
CHAT_MODEL_1_VLLM_MAX_CONTEXT_LENGTH=8192
CHAT_MODEL_1_VLLM_GPU_MEMORY_UTILIZATION=0.3
CHAT_MODEL_1_VLLM_CONTAINER_IMAGE="vllm/vllm-openai:v0.8.5.post1"
CHAT_MODEL_1_VLLM_CONTAINER_HOST_PORT=8001
CHAT_MODEL_2_NAME="Qwen 2.5 Coder, 32B"
CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_SOURCE="Qwen/Qwen2.5-Coder-32B-Instruct-AWQ"
CHAT_MODEL_2_VLLM_MAX_CONTEXT_LENGTH=8192
CHAT_MODEL_2_VLLM_GPU_MEMORY_UTILIZATION=0.9
CHAT_MODEL_2_VLLM_CONTAINER_IMAGE="vllm/vllm-openai:v0.8.5.post1"
CHAT_MODEL_2_VLLM_CONTAINER_HOST_PORT=8002
OPEN_WEBUI_CONTAINER_IMAGE="ghcr.io/open-webui/open-webui:cuda"
OPEN_WEBUI_CONTAINER_HOST_PORT=3000
TARGET_HOST=127.0.0.1
STOP_AND_REMOVE_PREEXISTING_PRIVATE_AI_CONTAINERS=true
AI_MODEL_LOADING_TIMEOUT=300
HUGGING_FACE_ACCESS_TOKEN=

# Start the AI Chat Model Dual Setup
echo "Starting the AI Chat Model Dual Setup..."

# Create the 'ai_models' Folder in the $HOME Directory
echo "Creating the 'ai_models' Folder in the $HOME Directory..."
mkdir -p $HOME/ai_models

# Define the Hugging Face Download Local Sub-Directories
CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY="${CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE##*/}"
CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY="${CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_SOURCE##*/}"

# Download the AI Chat Models
echo "Downloading the AI Chat Models..."
if $HUGGING_FACE_ACCESS_TOKEN; then
    HF_TOKEN=$HUGGING_FACE_ACCESS_TOKEN HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
    HF_TOKEN=$HUGGING_FACE_ACCESS_TOKEN HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
else
    HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
    HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download $CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_SOURCE --local-dir $HOME/ai_models/$CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY
fi

# Setup Docker Container Private AI Network
echo "Setting up Docker Container Private AI Network..."
sudo docker network create private-ai-setup-network 2>/dev/null

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

# Setup the vLLM Container with Chat Model 1 ($CHAT_MODEL_1_NAME)
echo "Setting up the vLLM Container with $CHAT_MODEL_1_NAME..."
if [ -z "$CHAT_MODEL_1_VLLM_MAX_CONTEXT_LENGTH" ]; then
    sudo docker run -d \
        --name vllm-chat-model-1 \
        --network private-ai-setup-network \
        -p $CHAT_MODEL_1_VLLM_CONTAINER_HOST_PORT:8000 \
        --runtime nvidia \
        --gpus all \
        -v $HOME/ai_models:/ai_models \
        --ipc=host \
        $CHAT_MODEL_1_VLLM_CONTAINER_IMAGE \
        --model /ai_models/$CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY \
        --served-model-name "$CHAT_MODEL_1_NAME" \
        --gpu_memory_utilization=$CHAT_MODEL_1_VLLM_GPU_MEMORY_UTILIZATION
else
    sudo docker run -d \
        --name vllm-chat-model-1 \
        --network private-ai-setup-network \
        -p $CHAT_MODEL_1_VLLM_CONTAINER_HOST_PORT:8000 \
        --runtime nvidia \
        --gpus all \
        -v $HOME/ai_models:/ai_models \
        --ipc=host \
        $CHAT_MODEL_1_VLLM_CONTAINER_IMAGE \
        --model /ai_models/$CHAT_MODEL_1_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY \
        --served-model-name "$CHAT_MODEL_1_NAME" \
        --gpu_memory_utilization=$CHAT_MODEL_1_VLLM_GPU_MEMORY_UTILIZATION \
        --max_model_len=$CHAT_MODEL_1_VLLM_MAX_CONTEXT_LENGTH
fi

if [[ $? -eq 0 ]]; then
    echo "The vLLM Container with $CHAT_MODEL_1_NAME has Started..."
else
    echo "ERROR: The vLLM Container with $CHAT_MODEL_1_NAME Failed to Start!"
    exit 1
fi

# Wait for the AI Model to Load ($CHAT_MODEL_1_NAME)
echo "The AI Model Loading Timeout is Set to $AI_MODEL_LOADING_TIMEOUT Second(s)."
echo "Waiting for $CHAT_MODEL_1_NAME to Load..."

## Perform an Inference Server Health Check for the Duration of $AI_MODEL_LOADING_TIMEOUT Seconds
START_TIME=$(date +%s)
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    if [ $ELAPSED_TIME -ge $AI_MODEL_LOADING_TIMEOUT ]; then
        echo
        echo "The Timeout for Loading $CHAT_MODEL_1_NAME Has Been Reached."
        echo "There May Be an Issue With the Inference Server or the Selected AI Model."
        echo "Please Check the Configuration and Try Again."
        exit 1
    fi

    if curl --silent --fail --output /dev/null "http://$TARGET_HOST:$CHAT_MODEL_1_VLLM_CONTAINER_HOST_PORT/health"; then
        echo
        echo "The AI Model $CHAT_MODEL_1_NAME Has Loaded Successfully."
        break
    else
        echo -n "."
        sleep 2
    fi
done
    
# Setup the vLLM Container with Chat Model 2 ($CHAT_MODEL_2_NAME)
echo "Setting up the vLLM Container with $CHAT_MODEL_2_NAME..."
if [ -z "$CHAT_MODEL_2_VLLM_MAX_CONTEXT_LENGTH" ]; then
    sudo docker run -d \
        --name vllm-chat-model-2 \
        --network private-ai-setup-network \
        -p $CHAT_MODEL_2_VLLM_CONTAINER_HOST_PORT:8000 \
        --runtime nvidia \
        --gpus all \
        -v $HOME/ai_models:/ai_models \
        --ipc=host \
        $CHAT_MODEL_2_VLLM_CONTAINER_IMAGE \
        --model /ai_models/$CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY \
        --served-model-name "$CHAT_MODEL_2_NAME" \
        --gpu_memory_utilization=$CHAT_MODEL_2_VLLM_GPU_MEMORY_UTILIZATION
else
    sudo docker run -d \
        --name vllm-chat-model-2 \
        --network private-ai-setup-network \
        -p $CHAT_MODEL_2_VLLM_CONTAINER_HOST_PORT:8000 \
        --runtime nvidia \
        --gpus all \
        -v $HOME/ai_models:/ai_models \
        --ipc=host \
        $CHAT_MODEL_2_VLLM_CONTAINER_IMAGE \
        --model /ai_models/$CHAT_MODEL_2_HUGGINGFACE_DOWNLOAD_LOCAL_SUB_DIRECTORY \
        --served-model-name "$CHAT_MODEL_2_NAME" \
        --gpu_memory_utilization=$CHAT_MODEL_2_VLLM_GPU_MEMORY_UTILIZATION \
        --max_model_len=$CHAT_MODEL_2_VLLM_MAX_CONTEXT_LENGTH
fi

if [[ $? -eq 0 ]]; then
    echo "The vLLM Container with $CHAT_MODEL_2_NAME has Started..."
else
    echo "ERROR: The vLLM Container with $CHAT_MODEL_2_NAME Failed to Start!"
    exit 1
fi

# Wait for the AI Model to Load ($CHAT_MODEL_2_NAME)
echo "The AI Model Loading Timeout is Set to $AI_MODEL_LOADING_TIMEOUT Second(s)."
echo "Waiting for $CHAT_MODEL_2_NAME to Load..."

## Perform an Inference Server Health Check for the Duration of $AI_MODEL_LOADING_TIMEOUT Seconds
START_TIME=$(date +%s)
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    if [ $ELAPSED_TIME -ge $AI_MODEL_LOADING_TIMEOUT ]; then
        echo
        echo "The Timeout for Loading $CHAT_MODEL_2_NAME Has Been Reached."
        echo "There May Be an Issue With the Inference Server or the Selected AI Model."
        echo "Please Check the Configuration and Try Again."
        exit 1
    fi

    if curl --silent --fail --output /dev/null "http://$TARGET_HOST:$CHAT_MODEL_2_VLLM_CONTAINER_HOST_PORT/health"; then
        echo
        echo "The AI Model $CHAT_MODEL_2_NAME Has Loaded Successfully."
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
    --network private-ai-setup-network \
    -p $OPEN_WEBUI_CONTAINER_HOST_PORT:8080 \
    --gpus all \
    -e WEBUI_AUTH="false" \
    -e WEBUI_NAME="Private AI" \
    -e OPENAI_API_BASE_URLS="http://vllm-chat-model-1:8000/v1;http://vllm-chat-model-2:8000/v1;http://sglang-vision-model-1:30000/v1;http://vllm-reasoning-model-1:8000/v1" \
    -e OPENAI_API_KEY="vllm-chat-model-1-sample-key;vllm-chat-model-2-sample-key;sglang-vision-model-1-sample-key;vllm-reasoning-model-1-sample-key" \
    -e DEFAULT_MODELS="$CHAT_MODEL_1_NAME" \
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

# End the AI Chat Model Dual Setup
echo "The AI Chat Model Dual Setup has Completed."
