BUILDBOX_NAME = $(shell ../internal/lib/docker_image_info.sh buildbox_name)
BUILDBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh buildbox_version)

TESTBOX_BASE_NAME = $(shell ../internal/lib/docker_image_info.sh testbox_base_name)
TESTBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh testbox_version)

.PHONY: all buildbox testboxes tag_latest upload tag_latest_buildbox tag_latest_testboxes upload_buildbox upload_testboxes testbox-debian-11 testbox-debian-10 testbox-debian-9 testbox-ubuntu-22.10 testbox-ubuntu-22.04 testbox-ubuntu-20.04 testbox-ubuntu-18.04 testbox-ubuntu-16.04

all: buildbox testboxes
testboxes: testbox-debian-11 testbox-debian-10 testbox-debian-9 testbox-ubuntu-22.10 testbox-ubuntu-22.04 testbox-ubuntu-20.04 testbox-ubuntu-18.04 testbox-ubuntu-16.04

buildbox:
	./setup-buildbox-docker-image "$(BUILDBOX_NAME):$(BUILDBOX_VERSION)"

testbox-debian-11:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_debian_11:$(TESTBOX_VERSION)" "testbox-debian-11"

testbox-debian-10:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_debian_10:$(TESTBOX_VERSION)" "testbox-debian-10"

testbox-debian-9:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION)" "testbox-debian-9"

testbox-ubuntu-22.10:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_ubuntu_22_10:$(TESTBOX_VERSION)" "testbox-ubuntu-22.10"

testbox-ubuntu-22.04:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_ubuntu_22_04:$(TESTBOX_VERSION)" "testbox-ubuntu-22.04"

testbox-ubuntu-20.04:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_ubuntu_20_04:$(TESTBOX_VERSION)" "testbox-ubuntu-20.04"

testbox-ubuntu-18.04:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_ubuntu_18_04:$(TESTBOX_VERSION)" "testbox-ubuntu-18.04"

testbox-ubuntu-16.04:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION)" "testbox-ubuntu-16.04"

tag_latest: tag_latest_buildbox tag_latest_testboxes

tag_latest_buildbox:
	docker tag $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-arm64 $(BUILDBOX_NAME):latest-arm64
	docker tag $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-amd64 $(BUILDBOX_NAME):latest-amd64

tag_latest_testboxes:
	docker tag $(TESTBOX_BASE_NAME)_debian_11:$(TESTBOX_VERSION)-arm64 $(TESTBOX_BASE_NAME)_debian_11:latest-arm64
	docker tag $(TESTBOX_BASE_NAME)_debian_11:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_debian_11:latest-amd64
	docker tag $(TESTBOX_BASE_NAME)_debian_10:$(TESTBOX_VERSION)-arm64 $(TESTBOX_BASE_NAME)_debian_10:latest-arm64
	docker tag $(TESTBOX_BASE_NAME)_debian_10:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_debian_10:latest-amd64
	docker tag $(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION)-arm64 $(TESTBOX_BASE_NAME)_debian_9:latest-arm64
	docker tag $(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_debian_9:latest-amd64
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_22_10:$(TESTBOX_VERSION)-arm64 $(TESTBOX_BASE_NAME)_ubuntu_22_10:latest-arm64
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_22_10:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_ubuntu_22_10:latest-amd64
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_22_04:$(TESTBOX_VERSION)-arm64 $(TESTBOX_BASE_NAME)_ubuntu_22_04:latest-arm64
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_22_04:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_ubuntu_22_04:latest-amd64
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_20_04:$(TESTBOX_VERSION)-arm64 $(TESTBOX_BASE_NAME)_ubuntu_20_04:latest-arm64
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_20_04:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_ubuntu_20_04:latest-amd64
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_18_04:$(TESTBOX_VERSION)-arm64 $(TESTBOX_BASE_NAME)_ubuntu_18_04:latest-arm64
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_18_04:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_ubuntu_18_04:latest-amd64
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION)-arm64 $(TESTBOX_BASE_NAME)_ubuntu_16_04:latest-arm64
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_ubuntu_16_04:latest-amd64

upload: upload_buildbox upload_testboxes

upload_buildbox: tag_latest_buildbox
	docker push $(BUILDBOX_NAME):latest-amd64
	docker push $(BUILDBOX_NAME):latest-arm64
	docker push $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-amd64
	docker push $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-arm64

release_buildbox: upload_buildbox
	docker manifest create $(BUILDBOX_NAME):$(BUILDBOX_VERSION) $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-amd64 $(BUILDBOX_NAME):$(BUILDBOX_VERSION)-arm64
	docker manifest create $(BUILDBOX_NAME):latest              $(BUILDBOX_NAME):latest-amd64              $(BUILDBOX_NAME):latest-arm64
	docker manifest push $(BUILDBOX_NAME):$(BUILDBOX_VERSION)
	docker manifest push $(BUILDBOX_NAME):latest

upload_testboxes: tag_latest_testboxes
	docker push $(TESTBOX_BASE_NAME)_debian_11:latest-amd64
	docker push $(TESTBOX_BASE_NAME)_debian_11:latest-arm64
	docker push $(TESTBOX_BASE_NAME)_debian_11:$(TESTBOX_VERSION)-amd64
	docker push $(TESTBOX_BASE_NAME)_debian_11:$(TESTBOX_VERSION)-arm64
	docker push $(TESTBOX_BASE_NAME)_debian_10:latest-amd64
	docker push $(TESTBOX_BASE_NAME)_debian_10:latest-arm64
	docker push $(TESTBOX_BASE_NAME)_debian_10:$(TESTBOX_VERSION)-amd64
	docker push $(TESTBOX_BASE_NAME)_debian_10:$(TESTBOX_VERSION)-arm64
	docker push $(TESTBOX_BASE_NAME)_debian_9:latest-amd64
	docker push $(TESTBOX_BASE_NAME)_debian_9:latest-arm64
	docker push $(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION)-amd64
	docker push $(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION)-arm64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_22_10:latest-amd64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_22_10:latest-arm64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_22_10:$(TESTBOX_VERSION)-amd64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_22_10:$(TESTBOX_VERSION)-arm64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_22_04:latest-amd64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_22_04:latest-arm64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_22_04:$(TESTBOX_VERSION)-amd64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_22_04:$(TESTBOX_VERSION)-arm64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_20_04:latest-amd64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_20_04:latest-arm64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_20_04:$(TESTBOX_VERSION)-amd64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_20_04:$(TESTBOX_VERSION)-arm64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_18_04:latest-amd64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_18_04:latest-arm64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_18_04:$(TESTBOX_VERSION)-amd64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_18_04:$(TESTBOX_VERSION)-arm64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_16_04:latest-amd64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_16_04:latest-arm64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION)-amd64
	docker push $(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION)-arm64

release_testboxes: upload_testboxes
	docker manifest create $(TESTBOX_BASE_NAME)_debian_11:latest             $(TESTBOX_BASE_NAME)_debian_11:latest-amd64             $(TESTBOX_BASE_NAME)_debian_11:latest-arm64
	docker manifest create $(TESTBOX_BASE_NAME)_debian_11:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_debian_11:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_debian_11:$(TESTBOX_VERSION)-arm64
	docker manifest push $(TESTBOX_BASE_NAME)_debian_11:latest
	docker manifest push $(TESTBOX_BASE_NAME)_debian_11:$(TESTBOX_VERSION)
	docker manifest create $(TESTBOX_BASE_NAME)_debian_10:latest             $(TESTBOX_BASE_NAME)_debian_10:latest-amd64             $(TESTBOX_BASE_NAME)_debian_10:latest-arm64
	docker manifest create $(TESTBOX_BASE_NAME)_debian_10:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_debian_10:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_debian_10:$(TESTBOX_VERSION)-arm64
	docker manifest push $(TESTBOX_BASE_NAME)_debian_10:latest
	docker manifest push $(TESTBOX_BASE_NAME)_debian_10:$(TESTBOX_VERSION)
	docker manifest create $(TESTBOX_BASE_NAME)_debian_9:latest             $(TESTBOX_BASE_NAME)_debian_9:latest-amd64             $(TESTBOX_BASE_NAME)_debian_9:latest-arm64
	docker manifest create $(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION)-arm64
	docker manifest push $(TESTBOX_BASE_NAME)_debian_9:latest
	docker manifest push $(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION)
	docker manifest create $(TESTBOX_BASE_NAME)_ubuntu_22_10:latest             $(TESTBOX_BASE_NAME)_ubuntu_22_10:latest-amd64             $(TESTBOX_BASE_NAME)_ubuntu_22_10:latest-arm64
	docker manifest create $(TESTBOX_BASE_NAME)_ubuntu_22_10:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_ubuntu_22_10:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_ubuntu_22_10:$(TESTBOX_VERSION)-arm64
	docker manifest push $(TESTBOX_BASE_NAME)_ubuntu_22_10:latest
	docker manifest push $(TESTBOX_BASE_NAME)_ubuntu_22_10:$(TESTBOX_VERSION)
	docker manifest create $(TESTBOX_BASE_NAME)_ubuntu_22_04:latest             $(TESTBOX_BASE_NAME)_ubuntu_22_04:latest-amd64             $(TESTBOX_BASE_NAME)_ubuntu_22_04:latest-arm64
	docker manifest create $(TESTBOX_BASE_NAME)_ubuntu_22_04:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_ubuntu_22_04:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_ubuntu_22_04:$(TESTBOX_VERSION)-arm64
	docker manifest push $(TESTBOX_BASE_NAME)_ubuntu_22_04:latest
	docker manifest push $(TESTBOX_BASE_NAME)_ubuntu_22_04:$(TESTBOX_VERSION)
	docker manifest create $(TESTBOX_BASE_NAME)_ubuntu_20_04:latest             $(TESTBOX_BASE_NAME)_ubuntu_20_04:latest-amd64             $(TESTBOX_BASE_NAME)_ubuntu_20_04:latest-arm64
	docker manifest create $(TESTBOX_BASE_NAME)_ubuntu_20_04:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_ubuntu_20_04:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_ubuntu_20_04:$(TESTBOX_VERSION)-arm64
	docker manifest push $(TESTBOX_BASE_NAME)_ubuntu_20_04:latest
	docker manifest push $(TESTBOX_BASE_NAME)_ubuntu_20_04:$(TESTBOX_VERSION)
	docker manifest create $(TESTBOX_BASE_NAME)_ubuntu_18_04:latest             $(TESTBOX_BASE_NAME)_ubuntu_18_04:latest-amd64             $(TESTBOX_BASE_NAME)_ubuntu_18_04:latest-arm64
	docker manifest create $(TESTBOX_BASE_NAME)_ubuntu_18_04:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_ubuntu_18_04:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_ubuntu_18_04:$(TESTBOX_VERSION)-arm64
	docker manifest push $(TESTBOX_BASE_NAME)_ubuntu_18_04:latest
	docker manifest push $(TESTBOX_BASE_NAME)_ubuntu_18_04:$(TESTBOX_VERSION)
	docker manifest create $(TESTBOX_BASE_NAME)_ubuntu_16_04:latest             $(TESTBOX_BASE_NAME)_ubuntu_16_04:latest-amd64             $(TESTBOX_BASE_NAME)_ubuntu_16_04:latest-arm64
	docker manifest create $(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION)-amd64 $(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION)-arm64
	docker manifest push $(TESTBOX_BASE_NAME)_ubuntu_16_04:latest
	docker manifest push $(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION)

release: release_buildbox release_testboxes
