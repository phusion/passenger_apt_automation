.PHONY: all buildbox testbox-ubuntu-14.04 testbox-ubuntu-10.04 upload

all: buildbox testbox-ubuntu-14.04 testbox-ubuntu-10.04

buildbox:
	./setup-buildbox-docker-image

testbox-ubuntu-14.04:
	./setup-testbox-docker-image-ubuntu-14.04

testbox-ubuntu-10.04:
	./setup-testbox-docker-image-ubuntu-10.04

upload:
	docker push phusion/passenger_apt_automation_buildbox
	docker push phusion/passenger_apt_automation_testbox_ubuntu_10_04
	docker push phusion/passenger_apt_automation_testbox_ubuntu_14_04
