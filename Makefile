DEBIAN_VERSION ?= jessie

DEBIAN_TALL_VERSION ?= jessie
DEBIAN_GRANDE_VERSION ?= jessie
DEBIAN_VENTI_VERSION ?= jessie

DEBIAN_VENTI_GOVERSIONS ?= 1.5.4 1.6.3 1.7 1.7.1 1.8.3 1.9.1

REGISTRY ?= quay.io/gravitational

DOCKER_COMMON_OPTS = --rm --privileged \
	-e DEBIAN_FRONTEND=noninteractive \
	-e http_proxy=$(http_proxy) \
	-v $(shell pwd):/build:ro

.PHONY: all
all: debian-tall debian-grande debian-venti debian-venti-go

.PHONY: images
images: debian-tall debian-grande debian-venti debian-venti-go

.PHONY: debian-tall
debian-tall:
	-docker rmi debian-tall:$(DEBIAN_TALL_VERSION)
	docker run $(DOCKER_COMMON_OPTS) debian:$(DEBIAN_VERSION) \
		bash /build/tall/build.sh > tall.tar
	docker import \
		tall.tar debian-tall:$(DEBIAN_TALL_VERSION)

.PHONY: debian-grande
debian-grande:
	-docker rmi debian-grande:$(DEBIAN_GRANDE_VERSION)
	docker run $(DOCKER_COMMON_OPTS) debian:$(DEBIAN_VERSION) \
		bash /build/grande/build.sh > grande.tar
	docker import \
		--change 'ENV DEBIAN_FRONTEND noninteractive' \
		grande.tar debian-grande:$(DEBIAN_GRANDE_VERSION)

.PHONY: debian-venti
debian-venti:
	-docker rmi debian-venti:$(DEBIAN_VENTI_VERSION)
	docker run $(DOCKER_COMMON_OPTS) debian:$(DEBIAN_VERSION) \
		bash /build/venti/build.sh > venti.tar
	docker import \
		--change 'ENV DEBIAN_FRONTEND noninteractive' \
		venti.tar debian-venti:$(DEBIAN_VENTI_VERSION)

.PHONY: debian-venti-go
debian-venti-go:
	for goversion in $(DEBIAN_VENTI_GOVERSIONS) ; do \
		docker rmi debian-venti:go$$goversion-$(DEBIAN_VENTI_VERSION) || true ; \
		docker build --build-arg GOVERSION=$$goversion -t debian-venti:go$$goversion-$(DEBIAN_VENTI_VERSION) venti ; \
	done

.PHONY: syntax-check
syntax-check:
	find . -name '*.sh' | xargs shellcheck

.PHONY: push
push:
	for goversion in $(DEBIAN_VENTI_GOVERSIONS); do \
		docker tag debian-venti:go$$goversion-$(DEBIAN_VENTI_VERSION) $(REGISTRY)/debian-venti:go$$goversion-$(DEBIAN_VENTI_VERSION) && \
		docker push $(REGISTRY)/debian-venti:go$$goversion-$(DEBIAN_VENTI_VERSION) ; \
	done
	# FIXME: for compatibility
	docker tag debian-venti:go1.5.4-$(DEBIAN_VENTI_VERSION) $(REGISTRY)/debian-venti:0.0.1
	docker tag debian-venti:$(DEBIAN_VENTI_VERSION) $(REGISTRY)/debian-venti:$(DEBIAN_TALL_VERSION)
	for version in 0.0.1 $(DEBIAN_TALL_VERSION); do \
		docker tag debian-tall:$(DEBIAN_TALL_VERSION) $(REGISTRY)/debian-tall:$$version && \
		docker tag debian-grande:$(DEBIAN_GRANDE_VERSION) $(REGISTRY)/debian-grande:$$version && \
		docker push $(REGISTRY)/debian-tall:$$version && \
		docker push $(REGISTRY)/debian-grande:$$version && \
		docker push $(REGISTRY)/debian-venti:$$version ; \
	done
