module Elemental

const libEl = "/opt/lib/libEl"

using MPI

type DistSparseMatrix{T} <: AbstractMatrix{T}
	obj::Ptr{Void}
end

function DistSparseMatrix(::Type{Float64}, comm::MPI.Comm = MPI.COMM_WORLD)
	obj = Ptr{Void}[0]
	ret = ccall((:ElDistSparseMatrixCreate_d, libEl), Cuint, (Ptr{Void}, Ptr{Cint}), &obj, &comm)
	return obj[1]
end

end # module
