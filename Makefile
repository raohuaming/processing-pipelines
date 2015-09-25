#
# Build docker images for IDInteraction processing pipelines.
#
# Robert Haines, University of Manchester.
#

# Docker usually needs to run as root, so make sure we do.
root := $(shell id -u)
ifeq ($(root),0)
	docker = docker
else
	docker = sudo docker
endif

.PHONY: all base cppmt tracking object-tracking video clean really-clean

all: .base .cppmt .tracking .video

# Use empty targets to help make, but hide them as dotfiles.
base: .base
.base: base/Dockerfile
	$(docker) build -t idinteraction/base base/
	touch .base

cppmt: .cppmt
.cppmt: .base cppmt/Dockerfile cppmt/Makefile
	$(MAKE) -C cppmt
	$(docker) build -t idinteraction/cppmt cppmt/
	touch .cppmt

tracking: .tracking
object-tracking: .tracking
.tracking: object-tracking/Dockerfile object-tracking/resources/Makefile
	$(docker) build -t idinteraction/object-tracking object-tracking/
	touch .tracking

video: .video
.video: .base video/Dockerfile video/resources/Makefile
	$(docker) build -t idinteraction/video video/
	touch .video

upload: all
	$(docker) push idinteraction/base
	$(docker) push idinteraction/cppmt
	$(docker) push idinteraction/object-tracking
	$(docker) push idinteraction/video

clean:
	rm -f .base .cppmt .tracking .video
	$(MAKE) -C cppmt clean
	-$(docker) stop `$(docker) ps -aq`
	-$(docker) rm -fv `$(docker) ps -aq`
	-$(docker) images -q --filter "dangling=true" | xargs $(docker) rmi

really-clean: clean
	-$(docker) rmi idinteraction/base
	-$(docker) rmi idinteraction/cppmt
	-$(docker) rmi idinteraction/object-tracking
	-$(docker) rmi idinteraction/video
