# NeuralSVG Container Environment

This repository provides a ready-to-use Docker-based environment for running [NeuralSVG](https://github.com/SagiPolaczek/NeuralSVG).
It automates the tricky pieces of the upstream installation—building the CUDA-enabled
[`diffvg`](https://github.com/BachiLi/diffvg) extension, installing PyTorch 2.4 with CUDA 12.1
support, and preparing helper scripts for downloading the released LoRA weights.

> **Why Docker?**  NeuralSVG relies on a large CUDA toolchain and several native dependencies.
> Packaging everything inside a container keeps the host system clean and guarantees that the
> compiled libraries (such as `diffvg`) match the PyTorch/CUDA stack shipped with the image.

## Repository Layout

```
├── docker/
│   ├── Dockerfile               # Builds the CUDA 12.1 environment with diffvg + NeuralSVG
│   └── .dockerignore            # Keeps the build context small
├── scripts/
│   ├── filter_requirements.py   # Helper used during the Docker build to filter requirements
│   └── download_loras.sh        # Convenience script for fetching the released LoRA weights
├── Makefile                     # High-level commands for building/running the container
└── workspace/                   # Created on demand to store outputs & downloaded assets
```

The NeuralSVG sources are cloned automatically inside the container at `/workspace/app`.
If you want to develop against a local checkout instead, you can bind mount it when
starting the container (see [Advanced usage](#advanced-usage)).

## Prerequisites

* Docker 24.0+ with the NVIDIA Container Toolkit configured for GPU passthrough.
  * The image uses `nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04` as its base.
* A GPU with CUDA 12 support is strongly recommended. There is also a `docker-run-cpu`
  target for experimentation without GPU acceleration, although training will be slow.

## Quick Start

1. **Build the image**

   ```bash
   make docker-build
   ```

   This downloads the base CUDA image, compiles `diffvg` from source, installs PyTorch 2.4.0,
   and pulls the latest NeuralSVG repository.

2. **Start an interactive container (with GPU)**

   ```bash
   make docker-run
   ```

   You will land in `/workspace/app`, which contains the cloned NeuralSVG repo and a Python
   environment with all dependencies pre-installed. The host directory `./workspace` is mounted
   at `/workspace/local` to persist experiment outputs, checkpoints, or custom configs.

3. **(Optional) Download the published LoRA weights**

   ```bash
   make download-loras
   ```

   The weights are stored on the host under `./workspace/lora_weights`, making them available
   across container sessions.

4. **Train a model**

   Inside the container you can run the upstream training scripts, for example:

   ```bash
   python scripts/train.py \
     --config_path config_files/run_shaping.yaml \
     --data.text_prompt="minimalist vector art of a sunflower" \
     --model.toggle_color="true" \
     --model.toggle_color_bg_colors="['light-red','light-green','light-blue','gold','gray']" \
     --model.lora_weights="/workspace/local/lora_weights/lora_weights_sd21b_bg_color.safetensors" \
     --log.exp_name="neuralsvg_sunflower"
   ```

   Replace the prompt and LoRA path as needed. Logs and SVG outputs can be written to the
   mounted `/workspace/local` directory to keep them on the host.

## Useful Make Targets

| Command              | Description |
| -------------------- | ----------- |
| `make docker-build`  | Build the Docker image defined in `docker/Dockerfile`. |
| `make docker-run`    | Run the image interactively with GPU access and the host `workspace/` mounted. |
| `make docker-run-cpu`| Same as above but without `--gpus all` (useful for CPU-only hosts). |
| `make download-loras`| Spawn a short-lived container that downloads LoRA weights into `workspace/lora_weights`. |

All targets accept overrides, e.g. `make docker-build IMAGE=my-neuralsvg DOCKERFILE=my.Dockerfile`.

## Advanced Usage

### Mount a local NeuralSVG checkout

If you prefer to work on a fork or a specific revision of NeuralSVG, mount your local
checkout into the container when starting it:

```bash
docker run --rm -it --gpus all \
  -v $(pwd)/my-neuralsvg:/workspace/app \
  -v $(pwd)/workspace:/workspace/local \
  neuralsvg-env
```

The Makefile targets can be adapted in the same way by setting environment variables or
editing the mount paths.

### Persisting Hugging Face credentials

The `huggingface-cli` command requires authentication for some assets. To reuse credentials
across sessions, mount your Hugging Face token file into the container when needed:

```bash
docker run --rm -it --gpus all \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -v $(pwd)/workspace:/workspace/local \
  neuralsvg-env
```

### Running without GPUs

`make docker-run-cpu` launches the same image without requesting a GPU. This path installs
the CUDA-enabled stack, so CPU execution works for testing but will be noticeably slower.
For a pure CPU base image you can point `DOCKERFILE` to a customised variant.

## Verifying the Environment

After launching the container you can quickly check that the core dependencies were installed
correctly:

```bash
python - <<'PY'
import diffvg, torch
print("diffvg version:", diffvg.__version__)
print("Torch CUDA available:", torch.cuda.is_available())
PY
```

You should see `True` for CUDA availability on GPU-capable hosts, and no import errors for
`diffvg`.

## Troubleshooting

* **`nvcc` or CUDA compilation errors while building diffvg** – ensure that the host exposes
  an NVIDIA driver version compatible with CUDA 12.1 (run `nvidia-smi`).
* **LoRA downloads fail** – verify that you are logged into the Hugging Face CLI inside the
  container (`huggingface-cli login`). The `make download-loras` target will reuse any cached
  credentials mounted under `~/.cache/huggingface`.
* **Want to use a CPU-only PyTorch wheel?**  Override the `pip install` line in the Dockerfile
  with the CPU index URL (`https://download.pytorch.org/whl/cpu`) and rebuild the image.

## License

This repository only contains orchestration assets (Dockerfile, helper scripts, docs) and is
released under the same license as NeuralSVG for convenience. Refer to the upstream project
for its licensing terms.
