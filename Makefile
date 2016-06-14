DEBIAN_VERSION ?= jessie

DEBIAN_TALL_VERSION ?= 0.0.1
DEBIAN_GRANDE_VERSION ?= 0.0.1
DEBIAN_VENTI_VERSION ?= 0.0.1

DOCKER_COMMON_OPTS = --rm --privileged \
	-e DEBIAN_FRONTEND=noninteractive \
	-e http_proxy=$(http_proxy) \
	-v $(shell pwd):/build:ro

.PHONY: all
all: debian-tall debian-grande debian-venti

.PHONY: debian-tall
debian-tall:
	-docker rmi debian-tall:$(DEBIAN_TALL_VERSION)
	docker run $(DOCKER_COMMON_OPTS) debian:$(DEBIAN_VERSION) \
		bash /build/tall/build.sh > tall.tar
	docker import \
		--change 'ONBUILD /bin/sh -c "test -x /cleanup.sh && sh /cleanup.sh"' \
		tall.tar debian-tall:$(DEBIAN_TALL_VERSION)

.PHONY: debian-grande
debian-grande:
	-docker rmi debian-grande:$(DEBIAN_GRANDE_VERSION)
	docker run $(DOCKER_COMMON_OPTS) debian:$(DEBIAN_VERSION) \
		bash /build/grande/build.sh > grande.tar
	docker import \
		--change 'ONBUILD /bin/sh -c "test -x /cleanup.sh && sh /cleanup.sh"' \
		--change 'ENV DEBIAN_FRONTEND noninteractive' \
		grande.tar debian-grande:$(DEBIAN_GRANDE_VERSION)

.PHONY: debian-venti
debian-venti:
	-docker rmi debian-venti:$(DEBIAN_VENTI_VERSION)
	docker run $(DOCKER_COMMON_OPTS) debian:$(DEBIAN_VERSION) \
		bash /build/venti/build.sh > venti.tar
	docker import \
		--change 'ONBUILD /bin/sh -c "test -x /cleanup.sh && sh /cleanup.sh"' \
		--change 'ENV DEBIAN_FRONTEND noninteractive' \
		--change "ENV GOROOT /go" \
		--change "ENV GOPATH /gocode" \
		--change "ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/go/bin:/gocode/bin" \
		venti.tar debian-venti:$(DEBIAN_VENTI_VERSION)

.PHONY: syntax-check
syntax-check:
	find . -name '*.sh' | xargs bashate -v

