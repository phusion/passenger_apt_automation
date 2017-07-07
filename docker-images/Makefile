.PHONY: all buildbox testboxes testbox-debian-9 testbox-debian-8 testbox-debian-7 testbox-ubuntu-17.04 testbox-ubuntu-16.04 testbox-ubuntu-14.04 testbox-ubuntu-12.04 upload

all: buildbox testboxes
testboxes: testbox-debian-9 testbox-debian-8 testbox-debian-7 testbox-ubuntu-17.04 testbox-ubuntu-16.04 testbox-ubuntu-14.04 testbox-ubuntu-12.04

buildbox:
	./setup-buildbox-docker-image

testbox-debian-9:
	./setup-testbox-docker-image-debian-9

testbox-debian-8:
	./setup-testbox-docker-image-debian-8

testbox-debian-7:
	./setup-testbox-docker-image-debian-7

testbox-ubuntu-17.04:
	./setup-testbox-docker-image-ubuntu-17.04

testbox-ubuntu-16.04:
	./setup-testbox-docker-image-ubuntu-16.04

testbox-ubuntu-14.04:
	./setup-testbox-docker-image-ubuntu-14.04

testbox-ubuntu-12.04:
	./setup-testbox-docker-image-ubuntu-12.04

upload:
	docker push phusion/passenger_apt_automation_buildbox
	docker push phusion/passenger_apt_automation_testbox_debian_9
	docker push phusion/passenger_apt_automation_testbox_debian_8
	docker push phusion/passenger_apt_automation_testbox_debian_7
	docker push phusion/passenger_apt_automation_testbox_ubuntu_17_04
	docker push phusion/passenger_apt_automation_testbox_ubuntu_16_04
	docker push phusion/passenger_apt_automation_testbox_ubuntu_14_04
	docker push phusion/passenger_apt_automation_testbox_ubuntu_12_04
