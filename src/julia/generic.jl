# Julia interface when not defined in source files

Base.eltype{T}(x::DistMultiVec{T}) = T

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

Base.copy!(A::T, B::T) where {T<:ElementalMatrix} = _copy!(B, A)
# copy(A::ElementalMatrix) = copy!(similar(A), A)
Base.length(A::ElementalMatrix) = prod(size(A))

## Current mutating Julia multiplication API
Base.A_mul_B!(C::T, A::T, B::T) where {T<:ElementalMatrix} = gemm(NORMAL, NORMAL, one(eltype(T)), A, B, zero(eltype(T)), C)
Base.Ac_mul_B!(C::T, A::T, B::T) where {T<:ElementalMatrix} = gemm(ADJOINT, NORMAL, one(eltype(T)), A, B, zero(eltype(T)), C)
Base.At_mul_B!(C::T, A::T, B::T) where {T<:ElementalMatrix} = gemm(TRANSPOSE, NORMAL, one(eltype(T)), A, B, zero(eltype(T)), C)
Base.A_mul_Bc!(C::T, A::T, B::T) where {T<:ElementalMatrix} = gemm(NORMAL, ADJOINT, one(eltype(T)), A, B, zero(eltype(T)), C)
Base.A_mul_Bt!(C::T, A::T, B::T) where {T<:ElementalMatrix} = gemm(NORMAL, TRANSPOSE, one(eltype(T)), A, B, zero(eltype(T)), C)

## BLAS like multiplication API (i.e. with α and β)
Base.A_mul_B!(α::Number, A::S, B::S, β::Number, C::S) where {S<:ElementalMatrix{T}} where {T} =
    gemm(NORMAL, NORMAL, T(α), A, B, T(β), C)
Base.Ac_mul_B!(α::Number, A::S, B::S, β::Number, C::S) where {S<:ElementalMatrix{T}} where {T} =
    gemm(ADJOINT, NORMAL, T(α), A, B, T(β), C)
Base.At_mul_B!(α::Number, A::S, B::S, β::Number, C::S) where {S<:ElementalMatrix{T}} where {T} =
    gemm(TRANSPOSE, NORMAL, T(α), A, B, T(β), C)
Base.A_mul_Bc!(α::Number, A::S, B::S, β::Number, C::S) where {S<:ElementalMatrix{T}} where {T} =
    gemm(NORMAL, ADJOINT, T(α), A, B, T(β), C)
Base.A_mul_Bt!(α::Number, A::S, B::S, β::Number, C::S) where {S<:ElementalMatrix{T}} where {T} =
    gemm(NORMAL, TRANSPOSE, T(α), A, B, T(β), C)

## Linear solve API
Base.LinAlg.A_ldiv_B!(A::LowerTriangular{T,S}, B::S)  where {T,S<:ElementalMatrix} =
    trsm(LEFT, LOWER, NORMAL   , NON_UNIT, one(T), A.data, B)
Base.LinAlg.Ac_ldiv_B!(A::LowerTriangular{T,S}, B::S) where {T,S<:ElementalMatrix} =
    trsm(LEFT, LOWER, ADJOINT  , NON_UNIT, one(T), A.data, B)
Base.LinAlg.At_ldiv_B!(A::LowerTriangular{T,S}, B::S) where {T,S<:ElementalMatrix} =
    trsm(LEFT, LOWER, TRANSPOSE, NON_UNIT, one(T), A.data, B)
Base.LinAlg.A_ldiv_B!(A::UpperTriangular{T,S}, B::S)  where {T,S<:ElementalMatrix} =
    trsm(LEFT, UPPER, NORMAL   , NON_UNIT, one(T), A.data, B)
Base.LinAlg.Ac_ldiv_B!(A::UpperTriangular{T,S}, B::S) where {T,S<:ElementalMatrix} =
    trsm(LEFT, UPPER, ADJOINT  , NON_UNIT, one(T), A.data, B)
Base.LinAlg.At_ldiv_B!(A::UpperTriangular{T,S}, B::S) where {T,S<:ElementalMatrix} =
    trsm(LEFT, UPPER, TRANSPOSE, NON_UNIT, one(T), A.data, B)

Base.LinAlg.A_rdiv_B!(A::S, B::LowerTriangular{T,S})  where {T,S<:ElementalMatrix} =
    trsm(RIGHT, LOWER, NORMAL   , NON_UNIT, one(T), B.data, A)
Base.LinAlg.A_rdiv_Bc!(A::S, B::LowerTriangular{T,S}) where {T,S<:ElementalMatrix} =
    trsm(RIGHT, LOWER, ADJOINT  , NON_UNIT, one(T), B.data, A)
Base.LinAlg.A_rdiv_Bt!(A::S, B::LowerTriangular{T,S}) where {T,S<:ElementalMatrix} =
    trsm(RIGHT, LOWER, TRANSPOSE, NON_UNIT, one(T), B.data, A)
Base.LinAlg.A_rdiv_B!(A::S, B::UpperTriangular{T,S})  where {T,S<:ElementalMatrix} =
    trsm(RIGHT, UPPER, NORMAL   , NON_UNIT, one(T), B.data, A)
Base.LinAlg.A_rdiv_Bc!(A::S, B::UpperTriangular{T,S}) where {T,S<:ElementalMatrix} =
    trsm(RIGHT, UPPER, ADJOINT  , NON_UNIT, one(T), B.data, A)
Base.LinAlg.A_rdiv_Bt!(A::S, B::UpperTriangular{T,S}) where {T,S<:ElementalMatrix} =
    trsm(RIGHT, UPPER, TRANSPOSE, NON_UNIT, one(T), B.data, A)

# Spectral
Base.LinAlg.svd(A::ElementalMatrix) = svd!(copy(A))
Base.LinAlg.svd(A::ElementalMatrix, ctrl::SVDCtrl) = svd!(copy(A), ctrl)
Base.LinAlg.svdvals(A::ElementalMatrix, ctrl::SVDCtrl) = svdvals!(copy(A), ctrl)

# conversions to and from julia arrays

# function copy!{T}(dest::Matrix{T}, src::Base.VecOrMat{T})
#     m, n = size(src, 1), size(src, 2)
#     resize!(dest, m, n)
#     Base.unsafe_copy!(pointer(dest), pointer(src), m*n)
#     return dest
# end
# function copy!{T}(dest::Base.Matrix{T}, src::Matrix{T})
#     m, n = size(dest)
#     if m != size(src, 1) || n != size(src, 2)
#         throw(DimensionMisMatch("source and destination must have same shape"))
#     end
#     Base.unsafe_copy!(pointer(dest), pointer(src), m*n)
#     return dest
# end

function Base.copy!{T}(dest::DistMatrix{T}, src::Base.VecOrMat)
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

function Base.convert{T}(::Type{Matrix{T}}, A::Base.VecOrMat{T})
    m, n = size(A, 1), size(A, 2)
    B = Matrix(T)
    resize!(B, m, n)
    Base.unsafe_copy!(pointer(B), pointer(A), m*n)
    return B
end
function Base.convert{T}(::Type{Base.Matrix{T}}, A::Matrix{T})
    m, n = size(A)
    B = Base.Matrix{T}(m, n)
    Base.unsafe_copy!(pointer(B), pointer(A), m*n)
    return B
end

function Base.convert{T}(::Type{DistMatrix{T}}, A::Base.VecOrMat{T})
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

function Base.convert{T}(::Type{DistMultiVec{T}}, A::Base.VecOrMat{T})
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

function Base.convert{T}(::Type{DistMatrix{T}}, A::DistMultiVec{T})
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

function Base.LinAlg.norm(x::ElementalMatrix)
    if size(x, 2) == 1
        return nrm2(x)
    else
        return twoNorm(x)
    end
end

# Multiplication
# (*){T}(A::DistMatrix{T}, B::Base.VecOrMat{T}) = A*convert(DistMatrix{T}, B)
# (*){T}(A::DistMultiVec{T}, B::Base.VecOrMat{T}) = convert(DistMatrix{T}, A)*convert(DistMatrix{T}, B)
# (*){T}(A::DistSparseMatrix{T}, B::Base.VecOrMat{T}) = A*convert(DistMultiVec{T}, B)
# Ac_mul_B{T}(A::DistMatrix{T}, B::Base.VecOrMat{T}) = Ac_mul_B(A, convert(DistMatrix{T}, B))
# Ac_mul_B{T}(A::DistMultiVec{T}, B::Base.VecOrMat{T}) = Ac_mul_B(convert(DistMatrix{T}, A), convert(DistMatrix{T}, B))
# Ac_mul_B{T}(A::DistSparseMatrix{T}, B::Base.VecOrMat{T}) = Ac_mul_B(A, convert(DistMultiVec{T}, B))

Base.cholfact!(A::Hermitian{<:Any,<:ElementalMatrix}, ::Type{Val{false}}) = Base.LinAlg.Cholesky(cholesky(A.uplo == 'U' ? UPPER : LOWER, A.data), A.uplo)
