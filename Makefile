CWD := $(shell pwd)
SOURCES := $(shell find source -name '*.d')
EXAMPLES := $(shell find examples -name '*.d')
TARGET_OS := $(shell uname -s)
LIBS_PATH := lib

.DEFAULT_GOAL := docs
all: docs

test:
	dub test
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
	rm -rf bin $(EXAMPLES)
	rm -f -- *.lst
.PHONY: clean

clean-docs:
	rm -f docs.json
	rm -f docs/sitemap.xml docs/file_hashes.json
	rm -rf `find docs -name '*.html'`
.PHONY: clean-docs
