.PHONY: setup generate clean

# The directory this Makefile resides in.
# NOTE: In some cases this is not a reliable way to get this path. But for this case it won't have any issues
# Read more at: https://lists.gnu.org/archive/html/help-make/2007-05/msg00059.html
makefileDir := $(dir $(firstword $(MAKEFILE_LIST)))
# Relative paths for Dart and Go proto directories given this Makefile location
goProto := ../../backend/proto
dartProto := ../../ui/lib/proto

setup:
	@echo "== Installing Buf CLI..."
	go install github.com/bufbuild/buf/cmd/buf@latest
	@echo "== Installing Go protoc plugins..."
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install connectrpc.com/connect/cmd/protoc-gen-connect-go@latest
	@echo "== Installing Dart protoc plugins..."
	dart pub global activate protoc_plugin 21.1.2
	dart pub global activate connectrpc
	@echo "== Setup complete"

generate:
	# Making sure we are at a correct working dir
	cd $(makefileDir)
	@echo "== Linting proto files and generating code."
	buf lint && buf generate
	@echo "== DONE generating!"
	@echo "== Distributing generated files around"
	cp -r gen/go/* $(goProto)
	cp -r gen/dart/* $(dartProto)

clean:
	rm -rf gen/
