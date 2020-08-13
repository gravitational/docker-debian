DEBIAN_VERSION ?= buster

REGISTRY ?= quay.io/gravitational

DEBIAN_VENTI_GOVERSIONS ?= 1.11.13 1.12.9 1.13

DOCKER_COMMON_OPTS = --rm --privileged \
	-e DEBIAN_FRONTEND=noninteractive \
	-e http_proxy=$(http_proxy) \
	-e DEBIAN_VERSION=$(DEBIAN_VERSION) \
	-v $(shell pwd):/build:ro

GO_VERSIONFILE:=go-versions.txt
INTERMEDIATE_GO_VERSIONFILE:=go-versions-partial.txt

.PHONY: all
all: images

.PHONY: images
images: debian-tall debian-grande debian-venti debian-venti-go

.PHONY: debian-tall
debian-tall:
	-docker rmi debian-tall:$(DEBIAN_VERSION)
	docker run $(DOCKER_COMMON_OPTS) \
		debian:$(DEBIAN_VERSION) bash /build/tall/build.sh > tall.tar
	docker import \
		tall.tar debian-tall:$(DEBIAN_VERSION)

.PHONY: debian-grande
debian-grande:
	-docker rmi debian-grande:$(DEBIAN_VERSION)
	docker run $(DOCKER_COMMON_OPTS) \
		debian:$(DEBIAN_VERSION) bash /build/grande/build.sh > grande.tar
	docker import \
		--change 'ENV DEBIAN_FRONTEND noninteractive' \
		grande.tar debian-grande:$(DEBIAN_VERSION)

.PHONY: debian-venti
debian-venti:
	-docker rmi debian-venti:$(DEBIAN_VERSION)
	docker run $(DOCKER_COMMON_OPTS) \
		debian:$(DEBIAN_VERSION) bash /build/venti/build.sh > venti.tar
	docker import \
		--change 'ENV DEBIAN_FRONTEND noninteractive' \
		venti.tar debian-venti:$(DEBIAN_VERSION)

.PHONY: go-versions
go-versions:
	rm -f $(INTERMEDIATE_GO_VERSIONFILE)
	echo $(DEBIAN_VENTI_GOVERSIONS) | tr " " "\n" >> $(INTERMEDIATE_GO_VERSIONFILE)
	./get_golang_versions.sh >> $(INTERMEDIATE_GO_VERSIONFILE)
	sort $(INTERMEDIATE_GO_VERSIONFILE) | uniq > $(GO_VERSIONFILE)
	rm -f $(INTERMEDIATE_GO_VERSIONFILE)

.PHONY: debian-venti-go
debian-venti-go: go-versions
	while read -r goversion; do \
		docker rmi debian-venti:go$$goversion-$(DEBIAN_VERSION) || true ; \
		docker build --build-arg GOVERSION=$$goversion -t debian-venti:go$$goversion-$(DEBIAN_VERSION) venti ; \
	done < $(GO_VERSIONFILE)

.PHONY: syntax-check
syntax-check:
	find . -name '*.sh' | xargs shellcheck

.PHONY: push
push: go-versions
	while read -r goversion; do \
		docker tag debian-venti:go$$goversion-$(DEBIAN_VERSION) $(REGISTRY)/debian-venti:go$$goversion-$(DEBIAN_VERSION) && \
		docker push $(REGISTRY)/debian-venti:go$$goversion-$(DEBIAN_VERSION) ; \
	done < $(GO_VERSIONFILE)
	docker tag debian-venti:$(DEBIAN_VERSION) $(REGISTRY)/debian-venti:$(DEBIAN_VERSION)
	for version in 0.0.3 $(DEBIAN_VERSION); do \
		docker tag debian-tall:$(DEBIAN_VERSION) $(REGISTRY)/debian-tall:$$version && \
		docker tag debian-grande:$(DEBIAN_VERSION) $(REGISTRY)/debian-grande:$$version && \
		docker push $(REGISTRY)/debian-tall:$$version && \
		docker push $(REGISTRY)/debian-grande:$$version ;\
	done
