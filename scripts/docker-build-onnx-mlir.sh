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
