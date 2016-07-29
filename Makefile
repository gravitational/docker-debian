DEBIAN_VERSION ?= jessie

DEBIAN_TALL_VERSION ?= 0.0.1
DEBIAN_GRANDE_VERSION ?= 0.0.1
DEBIAN_VENTI_VERSION ?= 0.0.1

REGISTRY ?= quay.io/gravitational

DOCKER_COMMON_OPTS = --rm --privileged \
	-e DEBIAN_FRONTEND=noninteractive \
	-e http_proxy=$(http_proxy) \
	-v $(shell pwd):/build:ro

.PHONY: all
all: debian-tall debian-grande debian-venti

.PHONY: images
images: debian-tall debian-grande debian-venti

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
		--change 'ENV GOROOT /go' \
		--change 'ENV GOPATH /gopath' \
		--change 'ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/go/bin:/gopath/bin' \
		venti.tar debian-venti:$(DEBIAN_VENTI_VERSION)

.PHONY: syntax-check
syntax-check:
	find . -name '*.sh' | xargs bashate -v

.PHONY: push
push:
	docker tag debian-tall:$(DEBIAN_TALL_VERSION) $(REGISTRY)/debian-tall:$(DEBIAN_TALL_VERSION)
	docker tag debian-tall:$(DEBIAN_TALL_VERSION) $(REGISTRY)/debian-tall:latest
	docker tag debian-grande:$(DEBIAN_GRANDE_VERSION) $(REGISTRY)/debian-grande:$(DEBIAN_GRANDE_VERSION)
	docker tag debian-grande:$(DEBIAN_GRANDE_VERSION) $(REGISTRY)/debian-grande:latest
	docker tag debian-venti:$(DEBIAN_VENTI_VERSION) $(REGISTRY)/debian-venti:$(DEBIAN_VENTI_VERSION)
	docker tag debian-venti:$(DEBIAN_VENTI_VERSION) $(REGISTRY)/debian-venti:latest
	docker push $(REGISTRY)/debian-tall:$(DEBIAN_TALL_VERSION)
	docker push $(REGISTRY)/debian-tall:latest
	docker push $(REGISTRY)/debian-grande:$(DEBIAN_GRANDE_VERSION)
	docker push $(REGISTRY)/debian-grande:latest
	docker push $(REGISTRY)/debian-venti:$(DEBIAN_VENTI_VERSION)
	docker push $(REGISTRY)/debian-venti:latest

