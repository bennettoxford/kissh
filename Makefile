TEST_IMAGE=ssh-test
export TEST=true

# disable default rules
.SUFFIXES:


.PHONY: lint
lint:
	shellcheck *.sh 
	black --check *.py


# proxy file to track image needing to be rebuilt
.test-image: Dockerfile
	docker build . -t $(TEST_IMAGE)
	touch $@


.PHONY: test-image
test-image: .test-image


# run all tests
.PHONY: test
test: $(TESTS)


# run specific test
TESTS=$(shell ls tests/*.sh)
.PHONY: $(TESTS)
$(TESTS): .test-image
	./run-test.sh $@
