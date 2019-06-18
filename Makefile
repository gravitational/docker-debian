UBUNTU_VERSION ?= bionic

UBUNTU_VENTI_GOVERSIONS ?= 1.8 1.9 1.10.3 1.10.7 1.10.8 1.11.4 1.11.5

REGISTRY ?= quay.io/gravitational

DOCKER_COMMON_OPTS = --rm --privileged \
	-e DEBIAN_FRONTEND=noninteractive \
	-e http_proxy=$(http_proxy) \
	-e UBUNTU_VERSION=$(UBUNTU_VERSION) \
	-v $(shell pwd):/build:ro

.PHONY: all
all: images

.PHONY: images
images: ubuntu-tall ubuntu-grande ubuntu-venti ubuntu-venti-go

.PHONY: ubuntu-tall
ubuntu-tall:
	-docker rmi ubuntu-tall:$(UBUNTU_VERSION)
	docker run $(DOCKER_COMMON_OPTS) \
		ubuntu:$(UBUNTU_VERSION) bash /build/tall/build.sh > tall.tar
	docker import \
		tall.tar ubuntu-tall:$(UBUNTU_VERSION)

.PHONY: ubuntu-grande
ubuntu-grande:
	-docker rmi ubuntu-grande:$(UBUNTU_VERSION)
	docker run $(DOCKER_COMMON_OPTS) \
		ubuntu:$(UBUNTU_VERSION) bash /build/grande/build.sh > grande.tar
	docker import \
		--change 'ENV DEBIAN_FRONTEND noninteractive' \
		grande.tar ubuntu-grande:$(UBUNTU_VERSION)

.PHONY: ubuntu-venti
ubuntu-venti:
	-docker rmi ubuntu-venti:$(UBUNTU_VERSION)
	docker run $(DOCKER_COMMON_OPTS) \
		ubuntu:$(UBUNTU_VERSION) bash /build/venti/build.sh > venti.tar
	docker import \
		--change 'ENV DEBIAN_FRONTEND noninteractive' \
		venti.tar ubuntu-venti:$(UBUNTU_VERSION)

.PHONY: ubuntu-venti-go
ubuntu-venti-go:
	for goversion in $(UBUNTU_VENTI_GOVERSIONS) ; do \
		docker rmi ubuntu-venti:go$$goversion-$(UBUNTU_VERSION) || true ; \
		docker build --build-arg GOVERSION=$$goversion -t ubuntu-venti:go$$goversion-$(UBUNTU_VERSION) venti ; \
	done

.PHONY: syntax-check
syntax-check:
	find . -name '*.sh' | xargs shellcheck

.PHONY: push
push:
	for goversion in $(UBUNTU_VENTI_GOVERSIONS); do \
		docker tag ubuntu-venti:go$$goversion-$(UBUNTU_VERSION) $(REGISTRY)/ubuntu-venti:go$$goversion-$(UBUNTU_VERSION) && \
		docker push $(REGISTRY)/ubuntu-venti:go$$goversion-$(UBUNTU_VERSION) ; \
	done
	docker tag ubuntu-venti:$(UBUNTU_VERSION) $(REGISTRY)/ubuntu-venti:$(UBUNTU_VERSION)
	for version in 0.0.2 $(UBUNTU_VERSION); do \
		docker tag ubuntu-tall:$(UBUNTU_VERSION) $(REGISTRY)/ubuntu-tall:$$version && \
		docker tag ubuntu-grande:$(UBUNTU_VERSION) $(REGISTRY)/ubuntu-grande:$$version && \
		docker push $(REGISTRY)/ubuntu-tall:$$version && \
		docker push $(REGISTRY)/ubuntu-grande:$$version && \
		docker push $(REGISTRY)/ubuntu-venti:$$version ; \
	done
