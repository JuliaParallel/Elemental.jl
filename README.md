# Elemental.jl

[![Build Status](https://travis-ci.org/JuliaParallel/Elemental.jl.svg?branch=master)](https://travis-ci.org/JuliaParallel/Elemental.jl)

A package for dense and sparse distributed linear algebra and optimization. The underlying functionality is provided by the C++ library [Elemental](https://github.com/LLNL/Elemental) written originally by [Jack Poulson](http://web.stanford.edu/~poulson/) and now maintained by LLNL.

## Installation
The package is installed with `Pkg.add("Elemental")`. For Julia versions 1.3 and later, Elemental uses the binaries provided by BinaryBuilder, which are linked against the MPI (mpich) provided through BinaryBuilder.

## Examples

Each of these examples should be run in a separate Julia session.

### Simple SVD example

This example runs on a single processor, and initializes MPI under the hood. However, explicit use of MPI.jl is not required in this case, compared to the other examples below.

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

julia> @mpi_do man using Elemental, TSVD, Random

julia> @mpi_do man A = Elemental.DistMatrix(Float64);

julia> @mpi_do man Elemental.gaussian!(A, 5000, 2000);

julia> @mpi_do man Random.seed!(123) # to avoid different initial vectors on the workers

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
