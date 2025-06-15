<h1 align="center">Private AI Setup Dream Guide for Demos</h1>

<br>
<p align="center">
  <img alt="Private AI Setup Dream Guide for Demos Title Graphic" title="Private AI Setup Dream Guide for Demos Title Graphic" src="./src/assets/private-ai-setup-dream-guide-title-graphic-001.png">
</p>  
<br>
<p align="center">
  Whether it's to show off the capabilities of AI to a friend or to sell AI Infrastructure to a business customer, the Private AI Setup Dream Guide for Demos automates the installation of the software needed for a local private AI setup, utilizing AI models (LLMs and diffusion models) for use cases such as general assistance, business ideas, coding, image generation, systems administration, marketing, planning, and more.
</p>
<br>

## AI Models - Default Deployment Options (Can Be Modified)
- [Meta Llama 3.1 8B Instruct](https://huggingface.co/RedHatAI/Meta-Llama-3.1-8B-Instruct-FP8-dynamic) - Chat Model
- [Qwen 2.5 Coder 32B Instruct](https://huggingface.co/Qwen/Qwen2.5-Coder-32B-Instruct-AWQ) - Chat Model
- [Qwen 2.5 VL 7B](https://huggingface.co/Qwen/Qwen2.5-VL-7B-Instruct) - Vision Model
- [Qwen 3 32B](https://huggingface.co/Qwen/Qwen3-32B-AWQ) - Reasoning Model
- [DeepSeek-R1 - Distilled Qwen 14B](https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Qwen-14B) - Reasoning Model
- [FLUX.1 Schnell](https://huggingface.co/black-forest-labs/FLUX.1-schnell) - Image Model
- [Stable Diffusion XL Base 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0) - Image Model

All of the AI models are downloaded from [Hugging Face](https://huggingface.co) and can be easily changed/updated to different models by editing the scripts.

## AI Frontend Menu Interfaces and Backend Inference Engines Deployed
- [Open WebUI](https://github.com/open-webui/open-webui) via Docker Container
- [Stable Diffusion WebUI Forge](https://github.com/lllyasviel/stable-diffusion-webui-forge) via Docker Container
- [vLLM](https://github.com/vllm-project/vllm) via Docker Container
- [SGLang](https://github.com/sgl-project/sglang) via Docker Container

## Default System Requirements (As Tested)
- Ubuntu 22.04.x Linux Operating System. Bare-metal installs are highly recommended.
- NVIDIA GPU supported by CUDA 12.5 or greater. The chosen default AI models were tested on an NVIDIA L40S GPU which has 48 GB of VRAM and supports FP8 precision. The AI models can be easily changed in the scripts to support different GPU models with lower or higher VRAM. An RTX 4090 has also been tested with the image models.
- At least 64 GB of system RAM is recommended. Lower system RAM may work, but has not been tested at this time.
- 205 GB of storage space. The stated storage space is based on deploying all of the chosen default AI models and Docker containers. The AI models can be easily changed in the scripts to support different storage space availability. Lower storage requirements will work if not all AI models and Docker containers are deployed.

## How To Use
1. Please ensure that the above [**Default System Requirements**](https://github.com/ugo-emekauwa/private-ai-setup-dream-guide#default-system-requirements) have been met.
2. Git clone or download the **Private AI Setup Dream Guide for Demos** repository:
  ```
  git clone https://github.com/ugo-emekauwa/private-ai-setup-dream-guide
  ```
3. Change directories to the private-ai-setup-dream-guide folder.
  ```
  cd private-ai-setup-dream-guide
  ```
4. Choose and run a pre-setup script to install all of the software packages and drivers needed to run the AI models. You have two options:

  - Option 1 - **Full Pre-Setup**: This will install the software packages and drivers needed to begin deploying the AI models. In addition, all of the default AI models and all of the Docker containers needed to run the AI models will also be downloaded. Depending on your Internet connection speed, the downloads may take a while, about 40-60 mins. Using the Full Pre-Setup option will take more time upfront, but will save you time later. **`WARNING:`** A server reboot is performed at the end of the script, so please save any work before starting.
  ```
  chmod +x full-pre-setup.sh
  ./full-pre-setup.sh
  ```

  - Option 2 - **Quick Pre-Setup**: This will install only the software packages and drivers needed to quickly begin deploying the AI models. None of the default AI models or Docker containers will be downloaded initially. Depending on your Internet connection speed, the downloads may take about 10-15 mins. The AI models and Docker containers will be downloaded later as each type of AI model is deployed via the corresponding script. **`WARNING:`** A server reboot is performed at the end of the script, so please save any work before starting.
  ```
  chmod +x full-pre-setup.sh
  ./quick-pre-setup.sh
  ```
5. Choose and run a model setup deployment script. There are several options based on what type of model you want to run:
  - **Single Chat Model Setup**: This script sets up an environment with one chat LLM. Meta Llama 3.1 8B Instruct has been chosen as the default chat AI model. Open WebUI provides a user-friendly GUI web interface with inferencing by vLLM.
  ```
  ./chat-model-single-setup.sh
  ```

  - **Dual Chat Model Setup**: This script sets up an environment with two chat LLMs. Meta Llama 3.1 8B Instruct and Qwen 2.5 Coder 32B Instruct have been chosen as the default chat AI models. Open WebUI provides a user-friendly GUI web interface with inferencing by vLLM.
  ```
  ./chat-model-dual-setup.sh
  ```

  - **Vision Model Setup**: This script sets up an environment with one vision language model. Qwen 2.5 VL 7B Instruct has been chosen as the default vision AI model. Open WebUI provides a user-friendly GUI web interface with inferencing by SGLang.
  ```
  ./vision-model-setup.sh
  ```

  - **Reasoning Model Setup with Qwen 3 32B**: This script sets up an environment with one reasoning LLM. Qwen 3 32B has been chosen as the default reasoning AI model. Open WebUI provides a user-friendly GUI web interface with inferencing by vLLM.
  ```
  ./reasoning-model-setup.sh
  ```
  **`TIP:`** The Qwen 3 reasoning models provide the capability to dynamically turn off thinking mode if a faster, but potentially less detailed and in-depth response is desired (similar to regular chat models). Use the tag `/no think` when prompting to temporarily disable thinking mode.

  - **Reasoning Model Setup with DeepSeek-R1**: This script sets up an environment with one reasoning LLM. DeepSeek-R1 (Distilled Qwen 14B) has been chosen as the default reasoning AI model. Open WebUI provides a user-friendly GUI web interface with inferencing by vLLM.
  ```
  ./reasoning-model-setup-alt.sh
  ```

  - **Image Model Setup**: This script sets up an environment with two AI image generation models, FLUX.1 Schnell and Stable Diffusion XL 1.0 Base. Stable Diffusion WebUI Forge provides a user-friendly GUI web interface and inferencing. **`NOTE:`** FLUX.1 Schnell is a gated model, meaning access must be given before it can be downloaded. To get access, setup an account on [Hugging Face](https://huggingface.co), gain access at https://huggingface.co/black-forest-labs/FLUX.1-schnell, and then setup a Hugging Face access token in your account. The access token only needs READ permissions. Finally, edit the **image-model-setup.sh** script to include your access token by setting the variable **HUGGING_FACE_ACCESS_TOKEN**. For example `HUGGING_FACE_ACCESS_TOKEN=hf_******************************IL7`. Otherwise, the script can still be used to setup the Stable Diffusion XL 1.0 Base model.
  ```
  ./image-model-setup.sh
  ```

To run the <ins>**FLUX.1 Schnell**</ins> model, perform the following steps in Stable Diffusion WebUI Forge:
  1. In the menu under the **UI** section, select the '**flux**' radio button preset.
  2. Under the **Checkpoint** section, select **flux1-schnell.safetensors**.
  3. Under the **VAE/Text Encoder** section, select **ae.safetensors**, **clip_l.safetensors**, and **t5xxl_fp16.safetensors** from the list. All must be selected.
  4. You're now ready to begin generating images. Under the **Txt2img** section tab, enter your prompt, then click the Generate button.
  <br><br>
  ![FLUX.1 Schnell Settings For SD WebUI Forge](./src/assets/image-model-setup-sample-016-flux.png "FLUX.1 Schnell Settings For SD WebUI Forge")
  <br><br>

To run the <ins>**Stable Diffusion XL 1.0 Base aka SDXL**</ins> model, perform the following steps in Stable Diffusion WebUI Forge:
  1. In the menu under the **UI** section, select the '**xl**' radio button preset.
  2. Under the **Checkpoint** section, select **sd_xl_base_1.0.safetensors**.
  3. Under the **VAE/Text Encoder** section, ensure the selection box is empty. If any entries were previously selected, use the **X** button to clear them.
  4. You're now ready to begin generating images. Under the **Txt2img** section tab, enter your prompt, then click the Generate button.
  <br><br>
  ![SDXL Settings For SD WebUI Forge](./src/assets/image-model-setup-sample-012-sdxl.png "SDXL Settings For SD WebUI Forge")
  <br><br>

  **`TIPS:`**
  - The first image generated will take longer than subsequent images, as the image model is initially loaded into the GPU VRAM.
  - The amount of GPU VRAM used can be adjusted under the **GPU Weights (MB)** section. Adjust this setting if you have any issues with GPU VRAM usage.
  - Under the **Generation** section tab, you may want to start with a lower number for **Sampling steps**, such as **10**. Lower Sampling steps will result in faster image generation, while higher Sampling steps may produce more detailed and accurate images. Play around with the settings to see what works best for your use case.
  - By default, each image generation with the same prompt will produce a different image. In the **Generation** section tab, under the **Seed** Section, use the button with the recycle icon to persist an image. This allows for the same image to be reproduced and modified upon. Use the button with the dice icon to return to random image generations.
  - Under the Generate button, the drop-down menu can be used to apply filters to the image generation.

## Sample Demonstration Work Flow Steps
- Exploring the chat model options with Meta Llama 3.1 and Qwen 2.5 Coder...
<br><br>
![Chat Model Options](./src/assets/chat-model-setup-sample-001.png "Chat Model Options")
<br><br>

- Using Qwen 2.5 Coder for assistance with coding...
<br><br>
![Coding Assistance Request](./src/assets/chat-model-setup-sample-002.png "Coding Assistance Request")
<br><br>
<br><br>
![Coding Assistance Results](./src/assets/chat-model-setup-sample-003.png "Coding Assistance Results")
<br><br>

- Running multiple chat models simultaneously with Meta Llama 3.1 and Qwen 2.5 Coder...
<br><br>
![Multiple Chat Models Selected](./src/assets/chat-model-setup-sample-004.png "Multiple Chat Models Selected")
<br><br>
<br><br>
![Multiple Chat Models Prompted](./src/assets/chat-model-setup-sample-005.png "Multiple Chat Models Prompted")
<br><br>

- Using FLUX.1 Schnell to generate an image with the prompt "an astronaut riding a horse on mars"...
<br><br>
![FLUX.1 Schnell Image Generation](./src/assets/image-model-setup-sample-007.png "FLUX.1 Schnell Image Generation")
<br><br>

- Using FLUX.1 Schnell to generate an image with the prompt "a robot sitting on a bench"...
<br><br>
![FLUX.1 Schnell Image Generation](./src/assets/image-model-setup-sample-005.png "FLUX.1 Schnell Image Generation")
<br><br>

- Using Stable Diffusion XL Base 1.0 to generate an image with the prompt "a ferrari driving down the city streets of tokyo"...
<br><br>
![Stable Diffusion XL Base 1.0 Image Generation](./src/assets/image-model-setup-sample-018-sdxl.png "Stable Diffusion XL Base 1.0 Image Generation")
<br><br>

- Using Qwen 2.5 VL to describe an image...
<br><br>
![Qwen 2.5 VL Description](./src/assets/vision-model-setup-sample-001.png "Qwen 2.5 VL Description")
<br><br>

- Exploring reasoning models with Qwen 3 32B...
<br><br>
![Reasoning Models](./src/assets/reasoning-model-setup-with-qwen-3-sample-001.png "Reasoning Models")
<br><br>

- Using Qwen 3 32B for assistance with coding...
<br><br>
![Coding Assistance Request](./src/assets/reasoning-model-setup-with-qwen-3-sample-002.png "Coding Assistance Request")
<br><br>
<br><br>
![Coding Assistance Results](./src/assets/reasoning-model-setup-with-qwen-3-sample-003.png "Coding Assistance Results")
<br><br>


###### 

## Demonstrations and Learning Labs
Private AI Setup Dream Guide for Demos is used in AI, Cisco UCS, and Intersight demonstrations and labs on Cisco dCloud:

- [Running Gen AI and LLMs on Cisco UCS X-Series with NVIDIA GPUs v2](https://dcloud2.cisco.com/demo/ai-workloads-on-cisco-ucs-x-series-v1) - _Coming Soon_
<br><br>

![Cisco UCS X-Series Lab Topology](./src/assets/Cisco_UCS_X-Series_Lab_Topology_2.png "Cisco UCS X-Series Lab Topology")
<br><br>

dCloud is available at [https://dcloud.cisco.com](https://dcloud.cisco.com), where Cisco product demonstrations and labs can be found in the Catalog.

## Author
Ugo Emekauwa

## Contact Information
uemekauw@cisco.com or uemekauwa@gmail.com
