module Elemental

using MPI
import Base: A_mul_B!, copy, copy!, similar, size

include("../deps/deps.jl")

# Detech MPI_Comm type
# commSameSizeAsInteger = Cint[0]
# err = ccall((:ElMPICommSameSizeAsInteger, libEl), Cuint, (Ptr{Cint},), commSameSizeAsInteger)
# if commSameSizeAsInteger[1] == 1
#     const MPI_COMM_WORLD = Ref{Cint}(0)
#     err = ccall((:ElMPICommWorld, libEl), Cuint, (Ptr{Cint},), MPI_COMM_WORLD)
# else
#     const MPI_COMM_WORLD = Ptr{Void}(0)
#     err = ccall((:ElMPICommWorld, libEl), Cuint, (Ptr{Void},), MPI_COMM_WORLD)
# end

# Detect Elemental integer size
using64 = Cint[0]
err = ccall((:ElUsing64BitInt, libEl), Cuint, (Ptr{Cint},), using64)
const ElInt = using64[1] == 1 ? Int64 : Int32

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
    err = ccall((:ElFinalize, libEl), Cint, 
        (),
        )
    err == 0 || error("something is wrong here!")
    return nothing
end

# core/types.h
const EL_NORMAL = Cint(0)
const EL_TRANSPOSE = Cint(1)
const EL_ADJOINT = Cint(2)

function __init__()
    MPI.Init()
    Init()
    # @show MPI.Comm_rank(MPI.COMM_WORLD)
    # Init()
    # @show Initialized()
end

type DistSparseMatrix{T} <: AbstractMatrix{T}
    obj::Ptr{Void}
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function DistSparseMatrix(::Type{$elty}, comm = MPI.COMM_WORLD)
            obj = Ref{Ptr{Void}}(C_NULL)
            err = ccall(($(string("ElDistSparseMatrixCreate_", ext)), libEl), Cuint,
                (Ref{Ptr{Void}}, Cint),
                obj, comm.val)
            err == 0 || error("something is wrong here!")
            return DistSparseMatrix{$elty}(obj[])
        end

        function DistSparseMatrix(::Type{$elty}, m::Integer, n::Integer, comm = MPI.COMM_WORLD)
            A = DistSparseMatrix($elty, comm)
            resize(A, m, n)
            return A
        end

        function destroy(A::DistSparseMatrix)
            err = ccall(($(string("ElDistSparseMatrixDestroy_", ext)), libEl), Cuint,
                (Ptr{Void},),
                A.obj)
            err == 0 || error("something is wrong here!")
            return 0
        end

        function resize{$elty}(A::DistSparseMatrix{$elty}, height::Integer, width::Integer)
            err = ccall(($(string("ElDistSparseMatrixResize_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt),
                A.obj, height, width)
            err == 0 || error("something is wrong here!")
            return A
        end

        function localHeight{$elty}(A::DistSparseMatrix{$elty})
            i = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixLocalHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, i)
            err == 0 || error("something is wrong here!")
            return i[]
        end

        function reserve{$elty}(A::DistSparseMatrix{$elty}, numEntries::Integer)
            err = ccall(($(string("ElDistSparseMatrixReserve_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt),
                A.obj, numEntries)
            err == 0 || error("something is wrong here!")
            return nothing
        end

        function globalRow{$elty}(A::DistSparseMatrix{$elty}, iLoc::Integer)
            i = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixGlobalRow_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, Ref{ElInt}),
                A.obj, iLoc, i)
            err == 0 || error("something is wrong here!")
            return i[]
        end

        function queueLocalUpdate{$elty}(A::DistSparseMatrix{$elty}, localRow::Integer, col::Integer, value::$elty)
            err = ccall(($(string("ElDistSparseMatrixQueueLocalUpdate_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty),
                A.obj, localRow, col, value)
            err == 0 || error("something is wrong here!")
            return nothing
        end

        function makeConsistent{$elty}(A::DistSparseMatrix{$elty})
            err = ccall(($(string("ElDistSparseMatrixMakeConsistent_", ext)), libEl), Cuint,
                (Ptr{Void},),
                A.obj)
            err == 0 || error("something is wrong here!")
            return nothing
        end

        function height{$elty}(A::DistSparseMatrix{$elty})
            i = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, i)
            err == 0 || error("something is wrong here!")
            return i[]
        end

        function width{$elty}(A::DistSparseMatrix{$elty})
            i = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixWidth_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, i)
            err == 0 || error("something is wrong here!")
            return i[]
        end

        function comm(A::DistSparseMatrix{$elty})
            cm = MPI.COMM_WORLD
            rcm = Ref{Cint}(cm.val)
            err = ccall(($(string("ElDistSparseMatrixComm_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{Cint}),
                A.obj, rcm)
            err == 0 || error("something is wrong here!")
            return cm
        end
    end
end




size(A::DistSparseMatrix) = (Int(height(A)), Int(width(A)))
# size(A::DistSparseMatrix) = (5,5)

# function show(io::IO, A::DistSparseMatrix)

# end

# DistMultiVec
type DistMultiVec{T} <: AbstractVector{T}
    obj::Ptr{Void}
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function DistMultiVec(::Type{$elty}, comm = MPI.COMM_WORLD)
            obj = Ref{Ptr{Void}}(C_NULL)
            err = ccall(($(string("ElDistMultiVecCreate_", ext)), libEl), Cuint,
                (Ref{Ptr{Void}}, Cint),
                obj, comm.val)
            err == 0 || error("something is wrong here!")
            return DistMultiVec{$elty}(obj[])
        end

        # function DistMultiVec(::Type{$elty}, m::Integer, n::Integer, comm = MPI.COMM_WORLD)
        #     obj = Ref{Ptr{Void}}(C_NULL)
        #     err = ccall(($(string("ElDistMultiVecCreate_", ext)), libEl), Cuint,
        #         (Ref{Ptr{Void}}, Cint),
        #         obj, comm.val)
        #     return DistMultiVec{$elty}(obj[])
        # end
        function height(x::DistMultiVec{$elty})
            i = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMultiVecHeight_", ext)), libEl), Cuint, 
                (Ptr{Void}, Ref{Cint}),
                x.obj, i)
            err == 0 || error("something is wrong here!")
            return i[]
        end
        

    end
end

eltype{T}(x::DistMultiVec{T}) = T
size(x::DistMultiVec) = (Int(height(x)),)
similar{T}(x::DistMultiVec{T}, cm = MPI.COMM_WORLD) = DistMultiVec(T, cm)

# matrices.h
for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))
    @eval begin
        function gaussian(A::DistMultiVec{$elty}, m::Integer, n::Integer, mean::$elty = zero($elty), stddev::$relty = one($relty))
            err = ccall(($(string("ElGaussianDistMultiVec_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty, $relty),
                A.obj, m, n, mean, stddev)
            err == 0 || error("something is wrong here!")
            return nothing
        end
    end
end

# blas_like/level1.h
for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))
    @eval begin
        function nrm2(x::DistMultiVec{$elty})
            nm = Ref{$relty}(0)
            err = ccall(($(string("ElNrm2DistMultiVec_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{$relty}),
                x.obj, nm)
            err == 0 || error("something is wrong here!")
            return nm[]
        end

        function copy!(src::DistMultiVec{$elty}, dest::DistMultiVec{$elty})
            err = ccall(($(string("ElCopyDistMultiVec_", ext)), libEl), Cuint,
                (Ptr{Void}, Ptr{Void}),
                src.obj, dest.obj)
            err == 0 || error("something is wrong here!")
            dest
        end
    end
end
copy(A::DistMultiVec) = copy!(A, similar(A))

# blas_like/level1.h
for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d), 
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))
    @eval begin
        function A_mul_B!(α::$elty, A::DistSparseMatrix{$elty}, x::DistMultiVec{$elty}, β::$elty, y::DistMultiVec{$elty})
            err = ccall(($(string("ElSparseMultiplyDist_", ext)), libEl), Cuint,
                (Cint, $elty, Ptr{Void}, Ptr{Void}, $elty, Ptr{Void}),
                EL_NORMAL, α, A.obj, x.obj, β, y.obj)
            err == 0 || error("something is wrong here!")
            return y
        end
    end
end

# lapack_like
## eucledian_min.h
for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin 
        function leastSquares!(A::DistSparseMatrix{$elty}, B::DistMultiVec{$elty}, X::DistMultiVec{$elty}; orientation::Integer = EL_NORMAL)
            err = ccall(($(string("ElLeastSquaresDistSparse_", ext)), libEl), Cuint, 
                (Cint, Ptr{Void}, Ptr{Void}, Ptr{Void}),
                orientation, A.obj, B.obj, X.obj)
            err == 0 || error("something is wrong here!")
            return X
        end
        function leastSquares(A::DistSparseMatrix{$elty}, B::DistMultiVec{$elty}; orientation::Integer = EL_NORMAL)
            X = similar(B, comm(A))
            return leastSquares!(A, B, X, orientation = orientation)
        end
    end
end

## factor.h
immutable RegQSDCtrl{T}
    regPrimal::T
    regDual::T
    alg::Cuint
    relTol::T
    relTolRefine::T
    maxRefineIts::Cint
    restart::Cint
    progress::Cint
end
for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin
        function RegQSDCtrl(::Type{$elty})
            obj = RegQSDCtrl{$elty}(0, 0, 0, 0, 0, 0, 0, 0)
            err = ccall(($(string("ElRegQSDCtrlDefault_", ext)), libEl), Cuint,
                (Ptr{RegQSDCtrl{$elty}},),
                &obj)
            err == 0 || error("something is wrong here!")
            return obj
        end
    end
end

# lapack_like/props.h
for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d), 
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))
    @eval begin
        function maxNorm(x::DistMultiVec{$elty})
            nm = Ref{$relty}(0)
            err = ccall(($(string("ElMaxNormDistMultiVec_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{$relty}),
                x.obj, nm)
            err == 0 || error("something is wrong here!")
            return nm[]
        end
        function entrywiseNorm(x::DistMultiVec{$elty}, p::Real)
            nm = Ref{$relty}(0)
            err = ccall(($(string("ElEntrywiseNormDistMultiVec_", ext)), libEl), Cuint,
                (Ptr{Void}, $relty, Ref{$relty}),
                x.obj, p, nm)
            err == 0 || error("something is wrong here!")
            return nm[]
        end
    end
end

# Optimization/solvers.h
immutable IPFLineSearchCtrl{T}
    gamma::T
    beta::T
    psi::T
    stepRatio::T
    progress::Cint
end
for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin
        function IPFLineSearchCtrl(::Type{$elty})
            obj = IPFLineSearchCtrl{$elty}(0, 0, 0, 0, 0)
            err = ccall(($(string("ElIPFLineSearchCtrlDefault_", ext)), libEl), Cuint,
                (Ptr{IPFLineSearchCtrl{$elty}},),
                 &obj)
            err == 0 || error("something is wrong here!")
            return obj
        end
    end
end

immutable LPAffineIPFCtrl{T}
    primalInit::Cint
    dualInit::Cint
    tol::T
    maxIts::Cint
    centering::T
    qsdCtrl::RegQSDCtrl{T}
    lineSearchCtrl::IPFLineSearchCtrl{T}
    equilibrate::Cint
    progress::Cint
    time::Cint
end
for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin
        function LPAffineIPFCtrl(::Type{$elty})
            obj = LPAffineIPFCtrl{$elty}(0, 0, 0, 0, 0, RegQSDCtrl($elty), IPFLineSearchCtrl($elty), 0, 0, 0)
            err = ccall(($(string("ElLPAffineIPFCtrlDefault_", ext)), libEl), Cuint,
                (Ptr{LPAffineIPFCtrl{$elty}},),
                 &obj)
            err == 0 || error("something is wrong here!")
            return obj
        end
    end
end

immutable LPAffineMehrotraCtrl{T}
    primalInit::Cint
    dualInit::Cint
    tol::T
    maxIts::Cint
    maxStepRatio::T
    qsdCtrl::RegQSDCtrl{T}
    outerEquil::Cint
    innerEquil::Cint
    scaleTwoNorm::Cint
    basisSize::Cint
    progress::Cint
    time::Cint
end
for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin
        function LPAffineMehrotraCtrl(::Type{$elty})
            obj = LPAffineMehrotraCtrl{$elty}(0, 0, 0, 0, 0, RegQSDCtrl($elty), 0, 0, 0, 0, 0, 0)
            err = ccall(($(string("ElLPAffineMehrotraCtrlDefault_", ext)), libEl), Cuint,
                (Ptr{LPAffineMehrotraCtrl{$elty}},),
                &obj)
            err == 0 || error("something is wrong here!")
            return obj
        end
    end
end


immutable LPAffineCtrl{T}
    approach::Cuint
    ipfCtrl::LPAffineIPFCtrl{T}
    mehrotraCtrl::LPAffineMehrotraCtrl{T}
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin
        function LPAffineCtrl(::Type{$elty})
            obj = LPAffineCtrl{$elty}(0, LPAffineIPFCtrl($elty), LPAffineMehrotraCtrl($elty))
            err = ccall(($(string("ElLPAffineCtrlDefault_", ext)), libEl), Cuint,
                (Ptr{LPAffineCtrl{$elty}},),
                &obj)
            err == 0 || error("something is wrong here!")
            return obj
        end
    end
end

# lapack_like/factor.h
# type RegQSDCtrl64
#     regPrimal::Float64
#     regDual::Float64
#     alg::Cuint
#     relTol::Float64
#     relTolRefine::Float64
#     maxRefineIts::Cint
#     restart::Cint
#     progress::Cint
# end
# for (elty, ext) in ((:Float64, :d),)
#     @eval begin
#         function RegQSDCtrl(::Type{$elty})
#             obj = RegQSDCtrl64(0, 0, 0, 0, 0, 0, 0, 0)
#             oref = Ref{RegQSDCtrl64}(obj)
#             err = ccall(($(string("ElRegQSDCtrlDefault_", ext)), libEl), Cuint,
#                 (Ref{RegQSDCtrl64},),
#                 oref)
#             return oref[]
#         end
#     end
# end

# # Optimization/solvers.h
# type IPFLineSearchCtrl64
#     gamma::Float64
#     beta::Float64
#     psi::Float64
#     stepRatio::Float64
#     progress::Cint
# end
# for (elty, ext) in ((:Float64, :d),)
#     @eval begin
#         function IPFLineSearchCtrl(::Type{$elty})
#             obj = IPFLineSearchCtrl64(0, 0, 0, 0, 0)
#             oref = Ref{IPFLineSearchCtrl64}(obj)
#             err = ccall(($(string("ElIPFLineSearchCtrlDefault_", ext)), libEl), Cuint,
#                 (Ref{IPFLineSearchCtrl64},),
#                  oref)
#             return oref[]
#         end
#     end
# end

# type LPAffineIPFCtrl64
#     primalInit::Cint
#     dualInit::Cint
#     tol::Float64
#     maxIts::Cint
#     centering::Float64
#     qsdCtrl::RegQSDCtrl64
#     lineSearchCtrl::IPFLineSearchCtrl64
#     equilibrate::Cint
#     progress::Cint
#     time::Cint
# end
# for (elty, ext) in ((:Float64, :d),)
#     @eval begin
#         function LPAffineIPFCtrl(::Type{$elty})
#             obj = LPAffineIPFCtrl64(0, 0, 0, 0, 0, RegQSDCtrl($elty), IPFLineSearchCtrl($elty), 0, 0, 0)
#             oref = Ref{LPAffineIPFCtrl64}(obj)
#             err = ccall(($(string("ElLPAffineIPFCtrlDefault_", ext)), libEl), Cuint,
#                 (Ref{LPAffineIPFCtrl64},),
#                  oref)
#             return oref[]
#         end
#     end
# end

# type LPAffineMehrotraCtrl64
#     primalInit::Cint
#     dualInit::Cint
#     tol::Float64
#     maxIts::Cint
#     maxStepRatio::Float64
#     qsdCtrl::RegQSDCtrl64
#     outerEquil::Cint
#     innerEquil::Cint
#     scaleTwoNorm::Cint
#     basisSize::Cint
#     progress::Cint
#     time::Cint
# end
# for (elty, ext) in ((:Float64, :d),)
#     @eval begin
#         function LPAffineMehrotraCtrl(::Type{$elty})
#             obj = LPAffineMehrotraCtrl64(0, 0, 0, 0, 0, RegQSDCtrl($elty), 0, 0, 0, 0, 0, 0)
#             oref = Ref{LPAffineMehrotraCtrl64}(obj)
#             err = ccall(($(string("ElLPAffineMehrotraCtrlDefault_", ext)), libEl), Cuint,
#                 (Ref{LPAffineMehrotraCtrl64},),
#                 oref)
#             return oref[]
#         end
#     end
# end


# type LPAffineCtrl64
#     approach::Cuint
#     ipfCtrl::LPAffineIPFCtrl64
#     mehrotraCtrl::LPAffineMehrotraCtrl64
# end

# for (elty, ext) in ((:Float64, :d),)
#     @eval begin
#         function LPAffineCtrl(::Type{$elty})
#             obj = LPAffineCtrl64(0, LPAffineIPFCtrl($elty), LPAffineMehrotraCtrl($elty))
#             oref = Ref{LPAffineCtrl64}(obj)
#             err = ccall(($(string("ElLPAffineCtrlDefault_", ext)), libEl), Cuint,
#                 (Ref{LPAffineCtrl64},),
#                 oref)
#             return oref[]
#         end
#     end
# end

# optimization/models.h
for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin

        function lav(A::DistSparseMatrix{$elty}, b::DistMultiVec{$elty})
            x = DistMultiVec($elty, comm(A))
            err = ccall(($(string("ElLAVDistSparse_", ext)), libEl), Cuint, 
                (Ptr{Void}, Ptr{Void}, Ptr{Void}),
                A.obj, b.obj, x.obj)
            err == 0 || error("something is wrong here!")
            return x
        end

        function lav(A::DistSparseMatrix{$elty}, b::DistMultiVec{$elty}, ctrl::LPAffineCtrl{$elty})
            x = DistMultiVec($elty, comm(A))
            err = ccall(($(string("ElLAVXDistSparse_", ext)), libEl), Cuint,
                (Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{LPAffineCtrl{$elty}}),
                A.obj, b.obj, x.obj, &ctrl)
            err == 0 || error("something is wrong here!")
            return x
        end
    end
end

end # module


# Using64BitInt
