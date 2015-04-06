module Elemental

using MPI

const libEl = "/Users/jacobbolewski/Julia/Elemental/build/libEl"

type DistSparseMatrix{T} <: AbstractMatrix{T}
	obj::Ptr{Void}
end

function DistSparseMatrix(::Type{Float64}, comm::MPI.Comm=MPI.COMM_WORLD)
	obj = Ref{Ptr{Void}}(C_NULL)
	ret = ccall((:ElDistSparseMatrixCreate_d, libEl), Cuint, (Ref{Ptr{Void}}, Cint), obj, comm.val)
	return obj[]
end

end # module
