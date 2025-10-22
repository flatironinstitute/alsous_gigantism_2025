# AG2025 – Software supporting Alsous et al. The physical consequences of sperm gigantism, Nat. Phys. 2025

---
## Simulation details
The sperm themselves are modeled as a chain of extensible rods with a centerline twist springs connecting pairs of
adjacent edges:

 n1       n3        n5        n7
  \      /  \      /  \      /
   s1   s2   s3   s4   s5   s6
    \  /      \  /      \  /
     n2        n4        n6

The centerline twist springs are hard to draw with ASCII art, but they are centered at every interior node and
connected to the node's neighbors:
c1 has a center node at n2 and connects to n1 and n3.
c2 has a center node at n3 and connects to n2 and n4.
and so on.

This means that, for example, s1 acts as a linear Hookean spring with a given rest length with a linear curvature-based 
angular spring connecting (n1, n2, n3), which attempt to drive the curvature at n2 to some prefered curvature. Here,
curvature is a 3 vector in the Lagrangian frame and constraints twist about the tangent and bending about the normal 
and binormal.

---
## How to install the dependencies for this code on FI's cluster
Always load the same dependencies!
```bash
module purge
module load modules/2.3-20240529
module load slurm cuda/12.3.2 openmpi/cuda-4.0.7 gcc/11.4.0 cmake/3.27.9 hwloc openblas hdf5 netcdf-c
```

Use spack to install trilinos/kokkos with GPU support
```bash
git clone --depth=2 --branch=releases/v0.23 https://github.com/spack/spack.git ~/spack
. ~/spack/share/spack/setup-env.sh
spack env create tril16_gpu
spack env activate tril16_gpu
spack external find cuda
spack external find cmake
spack external find openmpi
spack external find openblas
spack external find hdf5
spack external find hwloc

spack add kokkos+openmp+cuda+cuda_constexpr+cuda_lambda+cuda_relocatable_device_code~cuda_uvm~shared+wrapper cuda_arch=90 ^cuda@12.3.107 spack add magma+cuda cuda_arch=90 ^cuda@12.3.107 
spack add trilinos@16.0.0%gcc@11.4.0+belos~boost+exodus+hdf5+kokkos+openmp++cuda+cuda_rdc+stk+zoltan+zoltan2~shared~uvm+wrapper cuda_arch=90 cxxstd=17 ^cuda@12.3.107 ^openblas@0.3.26

spack concretize
spack install -j12
```

Install mundy and its small dependencies
```bash
git clone https://github.com/MundyRepo/MuNDy.git -b runtime
cd MuNDy
source ~/spack/share/spack/setup-env.sh
spack env activate tril16_gpu
module purge
module load modules/2.3-20240529
module load slurm cuda/12.3.2 openmpi/cuda-4.0.7 gcc/11.4.0 cmake/3.27.9 hwloc openblas hdf5 netcdf-c

cd dep
bash ./install_all.sh ~/spack/opt/spack/linux-rocky8-cascadelake/gcc-11.4.0/trilinos-16.0.0-2ldlcb6knaptx7q23x2jtdngukx6kc4e ~/envs/GPUMundyScratch/ 
cd ..

mkdir build && cd build
bash ../do-cmake-gpu.sh ~/spack/opt/spack/linux-rocky8-cascadelake/gcc-11.4.0/trilinos-16.0.0-2ldlcb6knaptx7q23x2jtdngukx6kc4e ~/envs/GPUMundyScratch/ ../ 
make -j12 
ctest -j12 --output-on-failure
install -j12
```

Please make sure that all tests pass before proceeding!

---
## Running the code
Load your dependencies before running:
```bash
source ~/spack/share/spack/setup-env.sh
spack env activate tril16_gpu
module purge
module load modules/2.3-20240529
module load slurm cuda/12.3.2 openmpi/cuda-4.0.7 gcc/11.4.0 cmake/3.27.9 hwloc openblas hdf5 netcdf-c
```

Run the code on an H100 via an interactive job:
```bash
cd build
srun --nodes=1 --constraint=h100 -p gpu --gpus=1 --ntasks=1 --cpus-per-task=1 --time=01:00:00 --pty bash -i
mpirun -n 1 ./mundy/alens/tests/performance_tests/MundyAlens_PeriodicCollidingOverdampedFrictionalSperm.exe
```

If you want a longer simulation, consider setting up a slurm file.
