module Elemental

using MPI
import Base: A_mul_B!, copy, copy!, similar, size

include("../deps/deps.jl")

# Detect Elemental integer size
function ELIntType()
    using64 = Cint[0]
    err = ccall((:ElUsing64BitInt, libEl), Cuint, (Ptr{Cint},), using64)
    return using64[1] == 1 ? Int64 : Int32
end
const ElInt = ElIntType()

function Init()
    err = ccall((:ElInitialize, libEl), Cint,
        (Ptr{Cint}, Ptr{Ptr{Void}}),
        &0, &C_NULL)
    err == 0 || error("something is wrong here!")
    return nothing
end

function Initialized()
    active = Cint[0]
    err = ccall((:ElInitialized, libEl), Cuint, (Ptr{Cint},), active)
    err == 0 || error("something is wrong here!")
    return active[1] == 1
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

include("types.jl")
include("distsparsematrix.jl")
include("distmultivec.jl")
include("matrices.jl")
include("blas_like/level1.jl")
include("blas_like/level3.jl")
include("lapack_like/eucledian_min.jl")
include("lapack_like/factor.jl")
include("lapack_like/props.jl")
include("optimization/solvers.jl")
include("optimization/models.jl")

end # module
