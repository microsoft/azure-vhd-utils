rwildcard=$(foreach d,$(filter-out ..,$(wildcard $1*)),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

.PHONY: all
all: test azure-vhd-utils lint fmt

.PHONY: lint
lint: azure-vhd-utils
	golint ./...

.PHONY: fmt
fmt: azure-vhd-utils
	go fmt ./...

azure-vhd-utils: $(call rwildcard, ., *.go)
	go build

.PHONY: test
test:
	go test ./...