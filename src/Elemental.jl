module Elemental

using MPI
import Base: A_mul_B!, copy, copy!, similar, size

include("../deps/deps.jl")

function Init()
    err = ccall((:ElInitialize, libEl), Cint,
        (Ref{Cint}, Ref{Ptr{Void}}), Ref(zero(Cint)), Ref(C_NULL))
    err == 0 || error("something is wrong here!")
    return nothing
end

function Initialized()
    active = Ref(zero(Cint))
    err = ccall((:ElInitialized, libEl), Cuint, (Ref{Cint},), active)
    err == 0 || error("something is wrong here!")
    return active[] == 1
end

function Finalize()
    err = ccall((:ElFinalize, libEl), Cint, ())
    err == 0 || error("something is wrong here!")
    return nothing
end

function __init__()
    MPI.Init()
    Init()
end

abstract ElementalMatrix{T} <: AbstractMatrix{T}

include("types.jl")
include("grid.jl")
include("sparsematrix.jl")
include("distmatrix.jl")
include("distsparsematrix.jl")
include("distmultivec.jl")
include("matrices.jl")
include("blas_like/level1.jl")
include("blas_like/level2.jl")
include("blas_like/level3.jl")
include("lapack_like/eucledian_min.jl")
include("lapack_like/factor.jl")
include("lapack_like/props.jl")
include("optimization/solvers.jl")
include("optimization/models.jl")

end # module
