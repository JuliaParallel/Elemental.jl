# Elemental.jl

[![Build Status](https://travis-ci.org/JuliaParallel/Elemental.jl.svg?branch=master)](https://travis-ci.org/JuliaParallel/Elemental.jl)

A package for dense and sparse distributed linear algebra and optimization. The underlying functionality is provided by the C++ library [Elemental](https://github.com/LLNL/Elemental) written originally by [Jack Poulson](http://web.stanford.edu/~poulson/) and now maintained by LLNL.

## Installation
The package is installed with `Pkg.add("Elemental")`. Priort to Julia 1.3, the install script automatically downloads *Elemental* and will try build against the BLAS library used by Julia. The library is now being prepared to ship Elemental with Julia's BinaryBuilder.

### MPI
The install script will build against any MPI installation that can be detected from calling `mpirun`. The package is tested with MPICH and OpenMPI but be aware that for OpenMPI at least version 1.8 is required because earlier versions of had bugs for complex data types. If you are using Linux and have installed OpenMPI from the repositories the version is (as always on Linux distributions) likely to be too old. Currently, MPICH isn't supported on macOS, see [this comment](https://github.com/pmodels/mpich/commit/2999a0ab3abc7a113d35d6117a9d1db8fa0ffa44#commitcomment-31131644) for details.

## Examples - SVD

### Simple example without MPI
```jl
julia> using LinearAlgebra, Elemental

julia> A = Elemental.Matrix(Float64)
0x0 Elemental.Matrix{Float64}

julia> Elemental.gaussian!(A, 100, 80);

julia> U, s, V = svd(A);

julia> convert(Matrix{Float64}, s)[1:10]
10-element Array{Float64,1}:
 19.8989
 18.2702
 17.3665
 17.0475
 16.4513
 16.3197
 16.0989
 15.8353
 15.5947
 15.5079
```

### Simple example with MPI

```jl
julia> using MPI, MPIClusterManagers, Distributed

julia> man = MPIManager(np = 4);

julia> addprocs(man);

julia> @everywhere using LinearAlgebra, Elemental

julia> @mpi_do man A = Elemental.DistMatrix(Float64);

julia> @mpi_do man Elemental.gaussian!(A, 1000, 800);

julia> @mpi_do man U, s, V = svd(A);

julia> @mpi_do man println(s[1])
    From worker 5:  59.639990420817696
    From worker 4:  59.639990420817696
    From worker 2:  59.639990420817696
    From worker 3:  59.639990420817696
```

### Simple example with DArrays

```jl
julia> using MPI, MPIClusterManagers, Distributed

julia> man = MPIManager(np = 4);

julia> addprocs(man);

julia> using DistributedArrays, Elemental

julia> A = drandn(1000, 800);

julia> Elemental.svdvals(A)[1:5]
5-element SubArray{Float64,1,DistributedArrays.DArray{Float64,2,Array{Float64,2}},Tuple{UnitRange{Int64}},0}:
 59.4649
 59.1984
 59.0309
 58.7178
 58.389
```

### Truncated SVD
The iterative SVD algorithm is implemented in pure Julia, but the factorized matrix as well as the Lanczos vectors are stored as distributed matrices in Elemental. Notice, that `TSVD.jl` doesn't depend on Elemental and is only using `Elemental.jl`'s through generic function calls.

```jl
julia> using MPI, MPIClusterManagers, Distributed

julia> man = MPIManager(np = 4);

julia> addprocs(man);

julia> @mpi_do man using Elemental, TSVD

julia> @mpi_do man A = Elemental.DistMatrix(Float64);

julia> @mpi_do man Elemental.gaussian!(A, 5000, 2000);

julia> @mpi_do man r = tsvd(A, 5);

julia> @mpi_do man println(r[2][1:5])
    From worker 3:  [1069.6059089732858,115.44260091060129,115.08319164529792,114.87007788947226,114.48092348847719]
    From worker 5:  [1069.6059089732858,115.44260091060129,115.08319164529792,114.87007788947226,114.48092348847719]
    From worker 2:  [1069.6059089732858,115.44260091060129,115.08319164529792,114.87007788947226,114.48092348847719]
    From worker 4:  [1069.6059089732858,115.44260091060129,115.08319164529792,114.87007788947226,114.48092348847719]
```

### Linear Regression

```jl
@mpi_do man A = Elemental.DistMatrix(Float32)
@mpi_do man B = Elemental.DistMatrix(Float32)
@mpi_do man copy!(A, Float32[2 1; 1 2])
@mpi_do man copy!(B, Float32[4, 5])
```

Run distributed ridge regression ` ½|A*X-B|₂² + λ|X|₂²`

```jl
@mpi_do man X = Elemental.ridge(A, B, 0f0)
```

Run distributed lasso regression ` ½|A*X-B|₂² + λ|X|₁` (only supported in recent versions of Elemental)

```jl
@mpi_do man X = Elemental.bpdn(A, B, 0.1f0)
```

### Coverage
We continually add functionality from *Elemental* to `Elemental.jl` so, right now, the best way to see if a specific function is available, is to look through the source code.
