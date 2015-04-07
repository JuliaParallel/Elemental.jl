module Elemental

# using MPI
import Base: size

const libEl = "/Users/andreasnoack/Elemental/build/libEl"

# Detech MPI_Comm type
commSameSizeAsInteger = Cint[0]
err = ccall((:ElMPICommSameSizeAsInteger, libEl), Cint, (Ptr{Cint},), commSameSizeAsInteger)
if commSameSizeAsInteger[1] == 1 
    const MPI_COMM_WORLD = Ref{Cint}(0)
    err = ccall((:ElMPICommWorld, libEl), Cint, (Ptr{Cint},), MPI_COMM_WORLD)
else 
    const MPI_COMM_WORLD = Ptr{Void}(0)
    err = ccall((:ElMPICommWorld, libEl), Cint, (Ptr{Void},), MPI_COMM_WORLD)
end

# Detect Elemental integer size
using64 = Cint[0]
err = ccall((:ElUsing64BitInt, libEl), Cint, (Ptr{Cint},), using64)
const ElInt = using64[1] == 1 ? Int64 : Int32

function __init__()
    println(MPI_COMM_WORLD)
    # MPI.Init()
    # @show MPI.Comm_rank(MPI.COMM_WORLD)
    err = ccall((:ElInitialize, libEl), Cint, 
        (Ptr{Cint}, Ptr{Ptr{Void}}),
        &0, &C_NULL)
    @show err
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

        function DistSparseMatrixResize{$elty}(A::DistSparseMatrix{$elty}, height::Integer, width::Integer)
            @show err = ccall(($(string("ElDistSparseMatrixResize_", ext)), libEl), Cint,
                (Ref{Ptr{Void}}, ElInt, ElInt), 
                A.obj, height, width)
            return A
        end

        function DistSparseMatrixLocalHeight{$elty}(A::DistSparseMatrix{$elty})
            height = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixLocalHeight_", ext)), libEl), Cint,
                (Ref{Ptr{Void}}, Ref{ElInt}), 
                A.obj, height)
            return convert(Int, height[])
        end
    end
end

size(A::DistSparseMatrix) = (DistSparseMatrixLocalHeight(A), (DistSparseMatrixLocalHeight(A)))
# size(A::DistSparseMatrix) = (5,5)


end # module


# Using64BitInt