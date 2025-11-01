TRILINOS_ROOT_DIR=$1
TPL_ROOT_DIR=$2

echo "Using Trilinos dir: $TRILINOS_ROOT_DIR"
echo "Using TPL dir: $TPL_ROOT_DIR"

# Find the nvcc_wrapper used for Kokkos
export OMPI_CXX=${TRILINOS_ROOT_DIR}/bin/nvcc_wrapper
export CUDA_LAUNCH_BLOCKING=1
export CUDA_MANAGED_FORCE_DEVICE_ALLOC=1

cmake \
-DCMAKE_BUILD_TYPE=${BUILD_TYPE:-RELEASE} \
-DCMAKE_CXX_COMPILER=${OMPI_CXX} \
-DCMAKE_CXX_FLAGS="-O3 -march=native -Wall -Wextra -Wdouble-promotion -Wconversion -lmpi -lcuda" \
-DCMAKE_INSTALL_PREFIX=$TPL_ROOT_DIR \
-DAG2025_ENABLE_UNIT_TESTS=OFF \
-DTrilinos_DIR=$TRILINOS_ROOT_DIR \
-DMundy_DIR=$TPL_ROOT_DIR \
${ccache_args} \
${compiler_flags} \
${install_dir} \
${extra_args} \
../
