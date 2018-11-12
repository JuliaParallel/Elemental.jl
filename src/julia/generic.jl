# Julia interface when not defined in source files

Base.eltype(x::DistMultiVec{T}) where {T} = T

function Base.size(A::ElementalMatrix, i::Integer)
    if i < 1
        error("dimension out of range")
    elseif i == 1
        return Int(height(A))
    elseif i == 2
        return Int(width(A))
    else
        return 1
    end
end

Base.size(A::ElementalMatrix) = (size(A, 1), size(A, 2))

Base.copyto!(A::T, B::T) where {T<:ElementalMatrix} = _copy!(B, A)
# copy(A::ElementalMatrix) = copy!(similar(A), A)
Base.length(A::ElementalMatrix) = prod(size(A))

## Current mutating Julia multiplication API
LinearAlgebra.mul!(C::T, A::T, B::T) where {T<:ElementalMatrix} = gemm(NORMAL, NORMAL, one(eltype(T)), A, B, zero(eltype(T)), C)
LinearAlgebra.mul!(C::T, adjA::Adjoint{<:Any,T}, B::T) where {T<:ElementalMatrix} = gemm(ADJOINT, NORMAL, one(eltype(T)), parent(adjA), B, zero(eltype(T)), C)
LinearAlgebra.mul!(C::T, trA::Transpose{<:Any,T}, B::T) where {T<:ElementalMatrix} = gemm(TRANSPOSE, NORMAL, one(eltype(T)), parent(trA), B, zero(eltype(T)), C)
LinearAlgebra.mul!(C::T, A::T, adjB::Adjoint{<:Any,T}) where {T<:ElementalMatrix} = gemm(NORMAL, ADJOINT, one(eltype(T)), A, parent(adjB), zero(eltype(T)), C)
LinearAlgebra.mul!(C::T, A::T, trB::Transpose{<:Any,T}) where {T<:ElementalMatrix} = gemm(NORMAL, TRANSPOSE, one(eltype(T)), A, parent(trB), zero(eltype(T)), C)

## BLAS like multiplication API (i.e. with α and β)
LinearAlgebra.mul!(C::S, A::S, B::S, α::Number, β::Number) where {S<:ElementalMatrix{T}} where {T} =
    gemm(NORMAL, NORMAL, T(α), A, B, T(β), C)
LinearAlgebra.mul!(C::S, adjA::Adjoint{<:Any,S}, B::S, α::Number, β::Number) where {S<:ElementalMatrix{T}} where {T} =
    gemm(ADJOINT, NORMAL, T(α), parent(adjA), B, T(β), C)
LinearAlgebra.mul!(C::S, trA::Transpose{<:Any,S}, B::S, α::Number, β::Number) where {S<:ElementalMatrix{T}} where {T} =
    gemm(TRANSPOSE, NORMAL, T(α), parent(trA), B, T(β), C)
LinearAlgebra.mul!(C::S, A::S, adjB::Adjoint{<:Any,S}, α::Number, β::Number) where {S<:ElementalMatrix{T}} where {T} =
    gemm(NORMAL, ADJOINT, T(α), A, parent(adjB), T(β), C)
LinearAlgebra.mul!(C::S, A::S, trB::Transpose{<:Any,S}, α::Number, β::Number) where {S<:ElementalMatrix{T}} where {T} =
    gemm(NORMAL, TRANSPOSE, T(α), A, parent(trB), T(β), C)

## Linear solve API
LinearAlgebra.ldiv!(A::LowerTriangular{T,S}, B::S)  where {T,S<:ElementalMatrix} =
    trsm(LEFT, LOWER, NORMAL   , NON_UNIT, one(T), A.data, B)
LinearAlgebra.ldiv!(adjA::Adjoint{T,LowerTriangular{T,S}}, B::S) where {T,S<:ElementalMatrix} =
    trsm(LEFT, LOWER, ADJOINT  , NON_UNIT, one(T), parent(adjA).data, B)
LinearAlgebra.ldiv!(trA::Transpose{T,LowerTriangular{T,S}}, B::S) where {T,S<:ElementalMatrix} =
    trsm(LEFT, LOWER, TRANSPOSE, NON_UNIT, one(T), parent(trA).data, B)
LinearAlgebra.ldiv!(A::UpperTriangular{T,S}, B::S)  where {T,S<:ElementalMatrix} =
    trsm(LEFT, UPPER, NORMAL   , NON_UNIT, one(T), A.data, B)
LinearAlgebra.ldiv!(adjA::Adjoint{T,UpperTriangular{T,S}}, B::S) where {T,S<:ElementalMatrix} =
    trsm(LEFT, UPPER, ADJOINT  , NON_UNIT, one(T), parent(adjA).data, B)
LinearAlgebra.ldiv!(trA::Transpose{T,UpperTriangular{T,S}}, B::S) where {T,S<:ElementalMatrix} =
    trsm(LEFT, UPPER, TRANSPOSE, NON_UNIT, one(T), parent(trA).data, B)

LinearAlgebra.rdiv!(A::S, B::LowerTriangular{T,S})  where {T,S<:ElementalMatrix} =
    trsm(RIGHT, LOWER, NORMAL   , NON_UNIT, one(T), B.data, A)
LinearAlgebra.rdiv!(A::S, adjB::Adjoint{T,LowerTriangular{T,S}}) where {T,S<:ElementalMatrix} =
    trsm(RIGHT, LOWER, ADJOINT  , NON_UNIT, one(T), parent(adjB).data, A)
LinearAlgebra.rdiv!(A::S, trB::Transpose{T,LowerTriangular{T,S}}) where {T,S<:ElementalMatrix} =
    trsm(RIGHT, LOWER, TRANSPOSE, NON_UNIT, one(T), B.data, A)
LinearAlgebra.rdiv!(A::S, B::UpperTriangular{T,S})  where {T,S<:ElementalMatrix} =
    trsm(RIGHT, UPPER, NORMAL   , NON_UNIT, one(T), B.data, A)
LinearAlgebra.rdiv!(A::S, adjB::Adjoint{T,UpperTriangular{T,S}}) where {T,S<:ElementalMatrix} =
    trsm(RIGHT, UPPER, ADJOINT  , NON_UNIT, one(T), parent(adjB).data, A)
LinearAlgebra.rdiv!(A::S, trB::Transpose{T,UpperTriangular{T,S}}) where {T,S<:ElementalMatrix} =
    trsm(RIGHT, UPPER, TRANSPOSE, NON_UNIT, one(T), parent(trB).data, A)

# Spectral
LinearAlgebra.svd(A::ElementalMatrix) = svd!(copy(A))
LinearAlgebra.svd(A::ElementalMatrix, ctrl::SVDCtrl) = svd!(copy(A), ctrl)
LinearAlgebra.svdvals(A::ElementalMatrix, ctrl::SVDCtrl) = svdvals!(copy(A), ctrl)

# conversions to and from julia arrays

# function copy!(dest::Matrix{T}, src::Base.VecOrMat{T}) where {T}
#     m, n = size(src, 1), size(src, 2)
#     resize!(dest, m, n)
#     Base.unsafe_copy!(pointer(dest), pointer(src), m*n)
#     return dest
# end
# function copy!(dest::Base.Matrix{T}, src::Matrix{T}) where {T}
#     m, n = size(dest)
#     if m != size(src, 1) || n != size(src, 2)
#         throw(DimensionMisMatch("source and destination must have same shape"))
#     end
#     Base.unsafe_copy!(pointer(dest), pointer(src), m*n)
#     return dest
# end

function Base.copy!(dest::DistMatrix{T}, src::Base.VecOrMat) where {T}
    m, n = size(src, 1), size(src, 2)
    zeros!(dest, m, n)
    if MPI.commRank(comm(dest)) == 0
        for j = 1:n
            for i = 1:m
                queueUpdate(dest, i, j, src[i,j])
            end
        end
    end
    processQueues(dest)
    return dest
end

function Base.convert(::Type{Matrix{T}}, A::Base.VecOrMat{T}) where {T}
    m, n = size(A, 1), size(A, 2)
    B = Matrix(T)
    resize!(B, m, n)
    Base.unsafe_copy!(pointer(B), pointer(A), m*n)
    return B
end
function Base.convert(::Type{Base.Matrix{T}}, A::Matrix{T}) where {T}
    m, n = size(A)
    B = Base.Matrix{T}(m, n)
    Base.unsafe_copy!(pointer(B), pointer(A), m*n)
    return B
end

function Base.convert(::Type{DistMatrix{T}}, A::Base.VecOrMat{T}) where {T}
    m, n = size(A, 1), size(A, 2)
    B = DistMatrix(T)
    zeros!(B, m, n)
    if MPI.commRank(comm(B)) == 0
        for j = 1:n
            for i = 1:m
                queueUpdate(B, i, j, A[i,j])
            end
        end
    end
    processQueues(B)
    return B
end

function Base.convert(::Type{DistMultiVec{T}}, A::Base.VecOrMat{T}) where {T}
    m, n = size(A, 1), size(A, 2)
    B = DistMultiVec(T)
    zeros!(B, m, n)
    if MPI.commRank(comm(B)) == 0
        for j = 1:n
            for i = 1:m
                queueUpdate(B, i, j, A[i,j])
            end
        end
    end
    processQueues(B)
    return B
end

function Base.convert(::Type{DistMatrix{T}}, A::DistMultiVec{T}) where {T}
    m, n = size(A)
    B = DistMatrix(T)
    zeros!(B, m, n)
    for j = 1:n
        for i = 1:localHeight(A)
            xij = getLocal(A, i, j)
            queueUpdate(B, globalRow(A, i), j, xij)
        end
    end
    processQueues(B)
    return B
end

LinearAlgebra.norm(x::ElementalMatrix) = nrm2(x)
# function LinearAlgebra.norm(x::ElementalMatrix)
#     if size(x, 2) == 1
#         return nrm2(x)
#     else
#         return twoNorm(x)
#     end
# end

LinearAlgebra.cholesky!(A::Hermitian{<:Union{Real,Complex},<:ElementalMatrix}) = LinearAlgebra.Cholesky(_cholesky!(A.uplo == 'U' ? UPPER : LOWER, A.data), A.uplo, 0)
LinearAlgebra.cholesky(A::Hermitian{<:Union{Real,Complex},<:ElementalMatrix}) = cholesky!(copy(A))

LinearAlgebra.lu(A::ElementalMatrix) = _lu!(copy(A))
