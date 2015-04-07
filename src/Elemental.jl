module Elemental

using MPI
import Base: size

const libEl = "/Users/andreasnoack/Elemental/build/libEl"

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

# function Init()
#     err = ccall((:ElInitialize, libEl), Cint, 
#         (Ptr{Cint}, Ptr{Ptr{Void}}),
#         &0, &C_NULL)
# end

# function Initialized()
#     active = Cint[0]
#     err = ccall((:ElInitialized, libEl), Cuint, (Ptr{Cint},), active)
#     return active[1] == 1
# end


function __init__()
    MPI.Init()
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
        function DistSparseMatrix(::Type{$elty}, comm = MPI_COMM_WORLD)
            obj = Ref{Ptr{Void}}(C_NULL)
            err = ccall(($(string("ElDistSparseMatrixCreate_", ext)), libEl), Cuint, 
                (Ref{Ptr{Void}}, Cint),
                obj, comm[])
            return DistSparseMatrix{$elty}(obj[])
        end

        function DistSparseMatrix(::Type{$elty}, m::Integer, n::Integer, comm = MPI_COMM_WORLD)
            A = DistSparseMatrix($elty, comm)
            DistSparseMatrixResize(A, m, n)
            return A
        end

        function destroy(A::DistSparseMatrix)
            err = ccall(($(string("ElDistSparseMatrixDestroy_", ext)), libEl), Cuint,
                (Ptr{Void},),
                A.obj)
            err
        end

        function DistSparseMatrixResize{$elty}(A::DistSparseMatrix{$elty}, height::Integer, width::Integer)
            @show err = ccall(($(string("ElDistSparseMatrixResize_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt), 
                A.obj, height, width)
            return A
        end

        function DistSparseMatrixLocalHeight{$elty}(A::DistSparseMatrix{$elty})
            height = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixLocalHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}), 
                A.obj, height)
            return convert(Int, height[])
        end


    end
end

# size(A::DistSparseMatrix) = (DistSparseMatrixLocalHeight(A), (DistSparseMatrixLocalHeight(A)))
size(A::DistSparseMatrix) = (5,5)


end # module


# Using64BitInt