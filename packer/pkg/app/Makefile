BINARY_DIR=bin

bin_dir:
	mkdir -p ${BINARY_DIR}

build_linux64: bin_dir
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o ./${BINARY_DIR}/app_linux64

build_win64: bin_dir
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o ./${BINARY_DIR}/app_win64.exe

build_osx64: bin_dir
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -o ./${BINARY_DIR}/app_osx64

build_all: build_linux64 build_win64 build_osx64
