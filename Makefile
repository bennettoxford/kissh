TESTS=$(shell ls tests/*.sh)
DISTRO=ubuntu

# disable default rules
.SUFFIXES:


.PHONY: lint
lint:
	shellcheck *.sh 
	black --check kissh

.PHONY: ubuntu-kissh-test-image debian-kissh-test-image
kissh-test-image-ubuntu:
	podman build . -t $@ --build-arg BASE=jrei/systemd-ubuntu:22.04
kissh-test-image-debian:
	podman build . -t $@ --build-arg BASE=jrei/systemd-debian:10


# run all tests
.PHONY: test
test: kissh-test-image-ubuntu kissh-test-image-debian
	$(MAKE) $(TESTS) DISTRO=ubuntu
	$(MAKE) $(TESTS) DISTRO=debian


.PHONY: $(TESTS)
$(TESTS): 
	./run-test.sh $@ kissh-test-image-$(DISTRO)


clean:
	podman rmi kissh-test-image-ubuntu kissh-test-image-debian
