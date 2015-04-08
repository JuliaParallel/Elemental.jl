type SparseMatrix{T} <: AbstractMatrix{T}
	obj::Ptr{Void}
end