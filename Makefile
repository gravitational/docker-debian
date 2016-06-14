DEBIAN_VERSION ?= jessie

DEBIAN_TALL_VERSION ?= 0.0.1
DEBIAN_GRANDE_VERSION ?= 0.0.1
DEBIAN_VENTI_VERSION ?= 0.0.1

DEBIAN_VENTI_CHANGE = --change "ENV GOROOT /go" --change "ENV GOPATH /gocode" \
	--change "ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/go/bin:/gocode/bin"

DOCKER_COMMON_OPTS = --rm --privileged --volume $(shell pwd):/build:ro \
	debian:$(DEBIAN_VERSION)

.PHONY: all
all: debian-tall debian-grande debian-venti

.PHONY: debian-tall
debian-tall:
	-docker rmi debian-tall:$(DEBIAN_TALL_VERSION)
	docker run $(DOCKER_COMMON_OPTS) bash /build/debian-tall.sh \
		| docker import - debian-tall:$(DEBIAN_TALL_VERSION)

.PHONY: debian-grande
debian-grande:
	-docker rmi debian-grande:$(DEBIAN_GRANDE_VERSION)
	docker run $(DOCKER_COMMON_OPTS) bash /build/debian-grande.sh \
		| docker import - debian-grande:$(DEBIAN_GRANDE_VERSION)

.PHONY: debian-venti
debian-venti:
	-docker rmi debian-venti:$(DEBIAN_VENTI_VERSION)
	docker run $(DOCKER_COMMON_OPTS) bash /build/debian-venti.sh \
		| docker import $(DEBIAN_VENTI_CHANGE) \
			- debian-venti:$(DEBIAN_VENTI_VERSION)

.PHONY: syntax-check
syntax-check:
	find . -name '*.sh' | xargs bashate -v

