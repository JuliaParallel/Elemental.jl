# Elemental.jl

[![Build Status](https://travis-ci.org/JuliaParallel/Elemental.jl.svg?branch=master)](https://travis-ci.org/JuliaParallel/Elemental.jl)

A package for dense and sparse distributed linear algebra and optimization. The underlying functionality is provided by the C++ library [Elemental](http://libelemental.org/) written by [Jack Poulson](http://web.stanford.edu/~poulson/).

## Installation
The package is installed with `Pkg.add("Elemenetal")`. The install script automatically downloads *Elemental* and will try build against the BLAS library used by Julia.

## Examples - SVD

### Simple example without MPI
```jl
julia> using Elemental

julia> A = Elemental.Matrix(Float64)
0x0 Elemental.Matrix{Float64}

julia> Elemental.gaussian!(A, 100, 80);

julia> U, s, V = Elemental.svd(A);

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
julia> using MPI

julia> man = MPIManager(np = 4);

julia> addprocs(man);

julia> using Elemental

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
julia> using MPI

julia> man = MPIManager(np = 4);

julia> addprocs(man);

julia> using DistributedArrays

julia> using Elemental

julia> A = drandn(1000, 800);

julia> svdvals(A)[1:5]
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
julia> using MPI

julia> man = MPIManager(np = 4);

julia> addprocs(man);

julia> using Elemental

julia> Pkg.clone("TSVD")

julia> @everywhere using TSVD

julia> @mpi_do man A = Elemental.DistMatrix(Float64);

julia> @mpi_do man Elemental.gaussian!(A, 5000, 2000);

julia> @mpi_do man r = tsvd(A, 5);

julia> @mpi_do man println(r[2][1:5])
    From worker 3:  [1069.6059089732858,115.44260091060129,115.08319164529792,114.87007788947226,114.48092348847719]
    From worker 5:  [1069.6059089732858,115.44260091060129,115.08319164529792,114.87007788947226,114.48092348847719]
    From worker 2:  [1069.6059089732858,115.44260091060129,115.08319164529792,114.87007788947226,114.48092348847719]
    From worker 4:  [1069.6059089732858,115.44260091060129,115.08319164529792,114.87007788947226,114.48092348847719]
```

### Coverage
We continually add functionality from *Elemental* to `Elemental.jl` so, right now, the best way to see if a specific function is available, is to look through the source code.

### Warning!
On Julia 0.4 workers will for `MethodError`s when one of the arguments is a pointer. This is fixed in 0.5 and will be back ported, but until that happens, you will have to be careful when calling new methods. An option is to wrap a call in a try/catch block and then print the exception instead of having it thrown.
