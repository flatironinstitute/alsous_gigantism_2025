TRILINOS_ROOT_DIR=$1
TPL_ROOT_DIR=$2

echo "Using Trilinos dir: $TRILINOS_ROOT_DIR"
echo "Using TPL dir: $TPL_ROOT_DIR"

cmake \
-DCMAKE_BUILD_TYPE=${BUILD_TYPE:-RELEASE} \
-DCMAKE_CXX_COMPILER=mpicxx \
-DCMAKE_CXX_FLAGS="-O3 -march=native" \
-DCMAKE_INSTALL_PREFIX=$TPL_ROOT_DIR \
-DAG2025_ENABLE_UNIT_TESTS=ON \
-DMundy_DIR=$TPL_ROOT_DIR \
${ccache_args} \
${compiler_flags} \
${install_dir} \
${extra_args} \
../
