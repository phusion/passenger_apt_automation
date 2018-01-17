BUILDBOX_NAME = $(shell ../internal/lib/docker_image_info.sh buildbox_name)
BUILDBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh buildbox_version)

TESTBOX_BASE_NAME = $(shell ../internal/lib/docker_image_info.sh testbox_base_name)
TESTBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh testbox_version)

.PHONY: all buildbox testboxes testbox-debian-9 testbox-debian-8 testbox-debian-7 testbox-ubuntu-17.10 testbox-ubuntu-16.04 testbox-ubuntu-14.04 upload

all: buildbox testboxes
testboxes: testbox-debian-9 testbox-debian-8 testbox-debian-7 testbox-ubuntu-17.10 testbox-ubuntu-16.04 testbox-ubuntu-14.04

buildbox:
	./setup-buildbox-docker-image "$(BUILDBOX_NAME):$(BUILDBOX_VERSION)"

testbox-debian-9:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION)" "testbox-debian-9"

testbox-debian-8:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_debian_8:$(TESTBOX_VERSION)" "testbox-debian-8"

testbox-debian-7:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_debian_7:$(TESTBOX_VERSION)" "testbox-debian-7"

testbox-ubuntu-17.10:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_ubuntu_17_10:$(TESTBOX_VERSION)" "testbox-ubuntu-17.10"

testbox-ubuntu-16.04:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION)" "testbox-ubuntu-16.04"

testbox-ubuntu-14.04:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_ubuntu_14_04:$(TESTBOX_VERSION)" "testbox-ubuntu-14.04"

tag_latest:
	docker tag $(BUILDBOX_NAME):$(BUILDBOX_VERSION) $(BUILDBOX_NAME):latest
	docker tag $(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_debian_9:latest
	docker tag $(TESTBOX_BASE_NAME)_debian_8:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_debian_8:latest
	docker tag $(TESTBOX_BASE_NAME)_debian_7:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_debian_7:latest
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_17_10:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_ubuntu_17_10:latest
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_ubuntu_16_04:latest
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_14_04:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_ubuntu_14_04:latest

upload: tag_latest
	docker push $(BUILDBOX_NAME)
	docker push $(TESTBOX_BASE_NAME)_debian_9
	docker push $(TESTBOX_BASE_NAME)_debian_8
	docker push $(TESTBOX_BASE_NAME)_debian_7
	docker push $(TESTBOX_BASE_NAME)_ubuntu_17_10
	docker push $(TESTBOX_BASE_NAME)_ubuntu_16_04
	docker push $(TESTBOX_BASE_NAME)_ubuntu_14_04
