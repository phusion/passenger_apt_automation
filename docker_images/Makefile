.PHONY: all buildbox testboxes testbox-debian-7 testbox-debian-6 testbox-ubuntu-14.04 testbox-ubuntu-12.04 testbox-ubuntu-10.04 upload

all: buildbox testboxes
testboxes: testbox-debian-7 testbox-debian-6 testbox-ubuntu-14.04 testbox-ubuntu-12.04 testbox-ubuntu-10.04

buildbox:
	./setup-buildbox-docker-image

testbox-debian-7:
	./setup-testbox-docker-image-debian-7

testbox-debian-6:
	./setup-testbox-docker-image-debian-6

testbox-ubuntu-14.04:
	./setup-testbox-docker-image-ubuntu-14.04

testbox-ubuntu-12.04:
	./setup-testbox-docker-image-ubuntu-12.04

testbox-ubuntu-10.04:
	./setup-testbox-docker-image-ubuntu-10.04

upload:
	docker push phusion/passenger_apt_automation_buildbox
	docker push phusion/passenger_apt_automation_testbox_debian_7
	docker push phusion/passenger_apt_automation_testbox_debian_6
	docker push phusion/passenger_apt_automation_testbox_ubuntu_10_04
	docker push phusion/passenger_apt_automation_testbox_ubuntu_12_04
	docker push phusion/passenger_apt_automation_testbox_ubuntu_14_04
