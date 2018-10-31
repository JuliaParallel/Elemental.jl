mutable struct SparseMatrix{T} <: AbstractMatrix{T}
	obj::Ptr{Cvoid}
end