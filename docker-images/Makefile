BUILDBOX_NAME = $(shell ../internal/lib/docker_image_info.sh buildbox_name)
BUILDBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh buildbox_version)

TESTBOX_BASE_NAME = $(shell ../internal/lib/docker_image_info.sh testbox_base_name)
TESTBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh testbox_version)

UBUNTUS          := $(shell source ../internal/lib/distro_info.sh; echo $$UBUNTU_DISTROS)
UBUNTU_TESTBOXES := $(foreach image, $(UBUNTUS), testbox-ubuntu-$(image))
UBUNTU_TAGGING   := $(foreach image, $(UBUNTUS), tag_latest_ubuntu_$(subst .,_,$(image))_testboxes)
UBUNTU_UPLOAD    := $(foreach image, $(UBUNTUS), upload_ubuntu_$(subst .,_,$(image))_testboxes)
UBUNTU_RELEASE   := $(foreach image, $(UBUNTUS), release_ubuntu_$(subst .,_,$(image))_testboxes)
DEBIANS          := $(shell source ../internal/lib/distro_info.sh; echo $$DEBIAN_DISTROS)
DEBIAN_TESTBOXES := $(foreach image, $(DEBIANS), testbox-debian-$(image))
DEBIAN_TAGGING   := $(foreach image, $(DEBIANS), tag_latest_debian_$(image)_testboxes)
DEBIAN_UPLOAD    := $(foreach image, $(DEBIANS), upload_debian_$(image)_testboxes)
DEBIAN_RELEASE   := $(foreach image, $(DEBIANS), release_debian_$(image)_testboxes)

.PHONY: all testboxes buildbox tag_latest tag_latest_buildbox tag_latest_testboxes upload upload_buildbox upload_testboxes release_buildbox release_testboxes release
FORCE:

all: buildbox testboxes
testboxes: $(DEBIAN_TESTBOXES) $(UBUNTU_TESTBOXES)

buildbox:
	./setup-buildbox-docker-image "$(BUILDBOX_NAME):$(BUILDBOX_VERSION)"

testbox-%: FORCE
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)" "testbox-$*"

pull_testbox_%: FORCE
	docker pull --platform linux/arm64 "ghcr.io/$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)-arm64"
	docker pull --platform linux/amd64 "ghcr.io/$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)-amd64"
	docker tag ghcr.io/"$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)-arm64" "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)-arm64"
	docker tag ghcr.io/"$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)-amd64" "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)-amd64"

tag_latest: tag_latest_buildbox tag_latest_testboxes

tag_latest_buildbox:
	docker tag $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-arm64 $(BUILDBOX_NAME):latest-arm64
	docker tag $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-amd64 $(BUILDBOX_NAME):latest-amd64

tag_latest_testboxes: $(DEBIAN_TAGGING) $(UBUNTU_TAGGING)

tag_latest_%_testboxes: FORCE
	docker tag "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)-arm64" "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):latest-arm64"
	docker tag "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)-amd64" "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):latest-amd64"

upload: upload_buildbox upload_testboxes

upload_buildbox: tag_latest_buildbox
	docker push $(BUILDBOX_NAME):latest-amd64
	docker push $(BUILDBOX_NAME):latest-arm64
	docker push $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-amd64
	docker push $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-arm64

release_buildbox: upload_buildbox
	docker manifest rm  $(BUILDBOX_NAME):latest || true
	docker manifest create $(BUILDBOX_NAME):$(BUILDBOX_VERSION) $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-amd64 $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-arm64
	docker manifest create $(BUILDBOX_NAME):latest              $(BUILDBOX_NAME):latest-amd64              $(BUILDBOX_NAME):latest-arm64
	docker manifest push $(BUILDBOX_NAME):$(BUILDBOX_VERSION)
	docker manifest push --purge $(BUILDBOX_NAME):latest

upload_testboxes: $(DEBIAN_UPLOAD) $(UBUNTU_UPLOAD)

upload_%_testboxes: tag_latest_%_testboxes FORCE
	docker push "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):latest-amd64"
	docker push "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):latest-arm64"
	docker push "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)-amd64"
	docker push "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)-arm64"

release_testboxes: $(DEBIAN_RELEASE) $(UBUNTU_RELEASE)

release_%_testboxes: upload_%_testboxes FORCE
	docker manifest rm           "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):latest" || true
	docker manifest create       "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):latest"             "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):latest-amd64"             "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):latest-arm64"
	docker manifest create       "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)" "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)-amd64" "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)-arm64"
	docker manifest push --purge "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):latest"
	docker manifest push         "$(TESTBOX_BASE_NAME)_$(subst .,_,$(subst -,_,$*)):$(TESTBOX_VERSION)"

release: release_buildbox release_testboxes
