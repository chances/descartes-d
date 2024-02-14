CWD := $(shell pwd)
SOURCES := $(shell find source -name '*.d')
TARGET_OS := $(shell uname -s)
LIBS_PATH := lib

.DEFAULT_GOAL := docs
all: docs

test:
	dub test
	@rm -f $(COVERAGE_TARGETS)
.PHONY: test

cover: $(SOURCES)
	dub test --coverage

PACKAGE_VERSION := 0.1.0
docs/sitemap.xml: $(SOURCES)
	dub build -b ddox
	# TODO: Cosmetic changes: https://github.com/chances/wasmer-d/blob/3da3ea6735138e369bd3f9cbf95d8664d3bde012/Makefile#L28-L42
	# @echo "Performing cosmetic changes..."
	@echo Done

docs: docs/sitemap.xml
.PHONY: docs

clean: clean-docs
	rm -rf bin coverage
.PHONY: clean

clean-docs:
ifeq ($(shell test -d docs && echo -n yes),yes)
	rm -f docs.json
	rm -f docs/sitemap.xml docs/file_hashes.json
	rm -rf `find docs -name '*.html'`
endif
.PHONY: clean-docs
