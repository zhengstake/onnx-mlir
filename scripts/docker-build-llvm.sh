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
