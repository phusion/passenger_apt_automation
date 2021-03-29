BUILDBOX_NAME = $(shell ../internal/lib/docker_image_info.sh buildbox_name)
BUILDBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh buildbox_version)

TESTBOX_BASE_NAME = $(shell ../internal/lib/docker_image_info.sh testbox_base_name)
TESTBOX_VERSION = $(shell ../internal/lib/docker_image_info.sh testbox_version)

.PHONY: all buildbox testboxes tag_latest upload testbox-debian-10 testbox-debian-9 testbox-ubuntu-20.10 testbox-ubuntu-20.04 testbox-ubuntu-18.04 testbox-ubuntu-16.04

all: buildbox testboxes
testboxes: testbox-debian-10 testbox-debian-9 testbox-ubuntu-20.10 testbox-ubuntu-20.04 testbox-ubuntu-18.04 testbox-ubuntu-16.04

buildbox:
	./setup-buildbox-docker-image "$(BUILDBOX_NAME):$(BUILDBOX_VERSION)"

testbox-debian-10:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_debian_10:$(TESTBOX_VERSION)" "testbox-debian-10"

testbox-debian-9:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION)" "testbox-debian-9"

testbox-ubuntu-20.10:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_ubuntu_20_10:$(TESTBOX_VERSION)" "testbox-ubuntu-20.10"

testbox-ubuntu-20.04:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_ubuntu_20_04:$(TESTBOX_VERSION)" "testbox-ubuntu-20.04"

testbox-ubuntu-18.04:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_ubuntu_18_04:$(TESTBOX_VERSION)" "testbox-ubuntu-18.04"

testbox-ubuntu-16.04:
	./setup-testbox-docker-image "$(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION)" "testbox-ubuntu-16.04"

tag_latest:
	docker tag $(BUILDBOX_NAME):$(BUILDBOX_VERSION) $(BUILDBOX_NAME):latest
	docker tag $(TESTBOX_BASE_NAME)_debian_10:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_debian_10:latest
	docker tag $(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_debian_9:latest
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_20_10:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_ubuntu_20_10:latest
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_20_04:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_ubuntu_20_04:latest
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_18_04:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_ubuntu_18_04:latest
	docker tag $(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION) $(TESTBOX_BASE_NAME)_ubuntu_16_04:latest

upload: tag_latest
	docker push $(BUILDBOX_NAME):latest
	docker push $(BUILDBOX_NAME):$(BUILDBOX_VERSION)
	docker push $(TESTBOX_BASE_NAME)_debian_10:latest
	docker push $(TESTBOX_BASE_NAME)_debian_10:$(TESTBOX_VERSION)
	docker push $(TESTBOX_BASE_NAME)_debian_9:latest
	docker push $(TESTBOX_BASE_NAME)_debian_9:$(TESTBOX_VERSION)
	docker push $(TESTBOX_BASE_NAME)_ubuntu_20_10:latest
	docker push $(TESTBOX_BASE_NAME)_ubuntu_20_10:$(TESTBOX_VERSION)
	docker push $(TESTBOX_BASE_NAME)_ubuntu_20_04:latest
	docker push $(TESTBOX_BASE_NAME)_ubuntu_20_04:$(TESTBOX_VERSION)
	docker push $(TESTBOX_BASE_NAME)_ubuntu_18_04:latest
	docker push $(TESTBOX_BASE_NAME)_ubuntu_18_04:$(TESTBOX_VERSION)
	docker push $(TESTBOX_BASE_NAME)_ubuntu_16_04:latest
	docker push $(TESTBOX_BASE_NAME)_ubuntu_16_04:$(TESTBOX_VERSION)
