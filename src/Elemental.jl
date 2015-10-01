module Elemental

using Compat

import Base: *
import Base: A_mul_B!, copy, copy!, getindex, print, setindex!, similar, size, svd,
    svdvals, svdvals!

include("../deps/deps.jl")

include("error.jl")

function Init()
    argc = Cint[0]
    argv = Vector{ASCIIString}[ASCIIString[""]]
    err = ccall((:ElInitialize, libEl), Cint,
                (Ptr{Cint}, Ptr{Ptr{Ptr{UInt8}}}), argc, pointer(argv))
    err == 0 || error("Error Initializing Elemental: $(ErrorString(err))")
    return nothing
end

function Initialized()
    active = Ref(zero(Cint))
    err = ccall((:ElInitialized, libEl), Cuint, (Ref{Cint},), active)
    err == 0 || throw(ElError(err))
    return active[] == 1
end

function Finalize()
    err = ccall((:ElFinalize, libEl), Cint, ())
    err == 0 || error("Error Finalizing Elemental: $(ErrorString(err))")
    return nothing
end

function __init__()
    Init()
    atexit() do
        Initialized() && Finalize()
    end
end

include("core/types.jl")
include("core/matrix.jl")
include("core/grid.jl")
include("core/sparsematrix.jl")
include("core/distmatrix.jl")
include("core/distsparsematrix.jl")
include("core/distmultivec.jl")
include("matrices.jl")
include("io.jl")
include("blas_like/level1.jl")
include("blas_like/level2.jl")
include("blas_like/level3.jl")
include("lapack_like/euclidean_min.jl")
include("lapack_like/factor.jl")
include("lapack_like/props.jl")
include("lapack_like/spectral.jl")
include("optimization/solvers.jl")
include("optimization/models.jl")
include("julia/generic.jl")
include("julia/darray.jl")

end # module
