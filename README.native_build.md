# This document is a HOWTO for building onnx-mlir Project step-by-step.

The document describes two flows:
1. native build flow on Ubuntu 22.04
2. docker build flow from base container onnxmlirczar/onnx-mlir 

last update on: 10/28/2023

## Native project diretory
Due to dependency of a specific commit of LLVM, the project directory is set up to use a designated checkout and build
of LLVM.

```tree
onnx-mlir-study
├── llvm-project
└── onnx-mlir
```

## Build llvm
ONNX-mlir depends on llvm. So first we need to build llvm based on a knowng working commit:

	git clone https://github.com/llvm/llvm-project.git

# Check out a specific branch that is known to work with ONNX-MLIR.
	cd llvm-project && git checkout d13da154a7c7eff77df8686b2de1cfdfa7cc7029 && cd ..
	git submodule update --init --recursive
	git fech --all

build and install llvm with the following script:

```bash
#!/usr/bin/env bash
enable_projects="clang;clang-tools-extra;lld;mlir"
#target_to_build="Native;NVPTX;AMDGPU"
target_to_build="Native;NVPTX;ARM;RISCV"
build_type="Release"

mkdir llvm-project/build
cd llvm-project/build
cmake -G Ninja ../llvm \
   -DCMAKE_BUILD_TYPE=${build_type} \
   -DLLVM_BUILD_EXAMPLES=ON \
   -DLLVM_CCACHE_BUILD=ON \
   -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLLVM_ENABLE_LLD=ON \
   -DLLVM_ENABLE_PROJECTS=${enable_projects} \
   -DLLVM_TARGETS_TO_BUILD=${target_to_build} \
   -DLLVM_ENABLE_ASSERTIONS=ON \
   -DLLVM_ENABLE_RTTI=ON \
   -DLLVM_ENABLE_LIBEDIT=OFF

cmake --build . -- ${MAKEFLAGS}
cmake --build . --target check-llvm

# Optionally, using ASAN/UBSAN can find bugs early in development, enable with:
# -DLLVM_USE_SANITIZER="Address;Undefined" 
# Optionally, enabling integration tests as well
# -DMLIR_INCLUDE_INTEGRATION_TESTS=ON
```

## create a python virtualenv
pyenv virtualenv 3.8.0 onnx-mlir
pip install -r requirements.txt
so ~/.pyenv/versions/onnx-mlir/bin/activate

## build and install correct version of protobuf library
The published docker file is using an older version of protobuf library
https://github.com/protocolbuffers/protobuf/releases/download/v3.20.3/protobuf-all-3.20.3.tar.gz
./autogen.sh 
./configure --enable-static=no --prefix=$(pwd)/Release
make -j${NPROC} install && ldconfig 
cd python && python3 setup.py install --cpp_implementation 


## Clone and build onnx-mlir
	git clone git@github.com:onnx/onnx-mlir.git
  git checkout ad9d7729
	git submodule update --init --recursive

Build using cmake with generator "Ninja" or "Unix Makefiles".
Controlling the number of jobs so that Linux OOM doesn't kill the build
due to running out of memory.

```bash
#!/usr/bin/env bash
# MLIR_DIR must be set with cmake option now
export MLIR_DIR=$(pwd)/llvm-project/build/lib/cmake/mlir
#BUILD="Debug"
BUILD="Release"
mkdir -p ./onnx-mlir/build-${BUILD} && cd ./onnx-mlir/build-${BUILD}
if [[ -z "$pythonLocation" ]]; then
  cmake -G "Unix Makefiles" \
        -DCMAKE_CXX_COMPILER=/usr/bin/c++ \
				-DCMAKE_BUILD_TYPE=${BUILD} \
				-DONNX_MLIR_ACCELERATORS=NNPA \
        -DMLIR_DIR=${MLIR_DIR} \
        ..
else
  cmake -G "Unix Makefiles" \
        -DCMAKE_CXX_COMPILER=/usr/bin/c++ \
	-DCMAKE_BUILD_TYPE=${BUILD} \
	-DONNX_MLIR_ACCELERATORS=NNPA \
        -DPython3_ROOT_DIR=$pythonLocation \
        -DMLIR_DIR=${MLIR_DIR} \
        ..
fi
cmake --build . -j 4

# Run lit tests:
export LIT_OPTS=-v
cmake --build . --target check-onnx-lit -j 4
```
