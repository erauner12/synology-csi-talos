#  Copyright 2021 Synology Inc.

REGISTRY_NAME=synology
IMAGE_NAME=synology-csi
IMAGE_VERSION=v1.2.0
IMAGE_TAG=$(REGISTRY_NAME)/$(IMAGE_NAME):$(IMAGE_VERSION)

# GitHub Container Registry settings
GITHUB_USER?=erauner
GHCR_REGISTRY=ghcr.io
GHCR_IMAGE_TAG=$(GHCR_REGISTRY)/$(GITHUB_USER)/$(IMAGE_NAME):$(IMAGE_VERSION)

# For now, only build linux/amd64 platform
ifeq ($(GOARCH),)
GOARCH:=amd64
endif
GOARM?=""
BUILD_ENV=CGO_ENABLED=0 GOOS=linux GOARCH=$(GOARCH) GOARM=$(GOARM)
BUILD_FLAGS="-s -w -extldflags \"-static\""

.PHONY: all clean synology-csi-driver synocli test docker-build

all: synology-csi-driver

synology-csi-driver:
	@mkdir -p bin
	$(BUILD_ENV) go build -v -ldflags $(BUILD_FLAGS) -o ./bin/synology-csi-driver ./

docker-build:
	docker build -f Dockerfile -t $(IMAGE_TAG) .

docker-build-multiarch:
	docker buildx build -t $(IMAGE_TAG) --platform linux/amd64,linux/arm/v7,linux/arm64 . --load

docker-build-multiarch-push:
	docker buildx build -t $(IMAGE_TAG) --platform linux/amd64,linux/arm/v7,linux/arm64 . --push

# Build and push to GitHub Container Registry
docker-build-multiarch-ghcr:
	docker buildx build -t $(GHCR_IMAGE_TAG) --platform linux/amd64,linux/arm/v7,linux/arm64 . --push

# Build locally for GitHub Container Registry (without push)
docker-build-multiarch-ghcr-local:
	docker buildx build -t $(GHCR_IMAGE_TAG) --platform linux/amd64,linux/arm/v7,linux/arm64 . --load

synocli:
	@mkdir -p bin
	$(BUILD_ENV) go build -v -ldflags $(BUILD_FLAGS) -o ./bin/synocli ./synocli

test:
	go clean -testcache
	go test -v ./test/...
clean:
	-rm -rf ./bin

