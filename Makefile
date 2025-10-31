IMAGE ?= neuralsvg-env
DOCKERFILE ?= docker/Dockerfile
WORKSPACE_DIR ?= $(CURDIR)/workspace

.PHONY: docker-build docker-run docker-run-cpu docker-shell download-loras ensure-workspace

ensure-workspace:
	mkdir -p $(WORKSPACE_DIR)

docker-build:
	docker build --pull --file $(DOCKERFILE) --tag $(IMAGE) .

docker-run: ensure-workspace
	docker run --rm -it --gpus all \
		-v $(WORKSPACE_DIR):/workspace/local \
		$(IMAGE)

docker-run-cpu: ensure-workspace
	docker run --rm -it \
		-v $(WORKSPACE_DIR):/workspace/local \
		$(IMAGE)

docker-shell: docker-run

# Convenience wrapper around the helper script that pulls NeuralSVG LoRA weights.
download-loras: ensure-workspace
	docker run --rm -it --gpus all \
		-v $(WORKSPACE_DIR):/workspace/local \
		$(IMAGE) \
		bash -lc "download_loras.sh /workspace/app /workspace/local/lora_weights"
