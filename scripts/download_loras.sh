#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=${1:-/workspace/app}
TARGET_DIR=${2:-$REPO_DIR/lora_weights}

if ! command -v huggingface-cli >/dev/null 2>&1; then
  echo "huggingface-cli is not installed. Please run 'pip install huggingface_hub' first." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "Downloading NeuralSVG LoRA weights into $(pwd)..."
huggingface-cli download   SagiPolaczek/SD2.1-NeuralSVG-LoRAs   lora_weights_sd21b_bg_color.safetensors   lora_weights_sd21b_bg_color_colorful.safetensors   lora_weights_sd21b_sketches.safetensors   --local-dir .

echo "Done."
