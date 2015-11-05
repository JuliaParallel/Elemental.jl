# Julia interface when not defined in source files

eltype{T}(x::DistMultiVec{T}) = T

function size(A::ElementalMatrix, i::Integer)
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

size(A::ElementalMatrix) = (size(A, 1), size(A, 2))

(*){T<:ElementalMatrix}(A::T, B::T)      = A_mul_B!(one(eltype(A)), A, B, zero(eltype(A)), similar(A, (size(A, 1), size(B, 2))))
(*){T}(A::DistSparseMatrix{T}, B::DistMultiVec{T}) = A_mul_B!(one(T), A, B, zero(T), similar(B, (size(A, 1), size(B, 2))))
Ac_mul_B{T<:ElementalMatrix}(A::T, B::T) = Ac_mul_B!(one(eltype(A)), A, B, zero(eltype(A)), similar(A, (size(A, 2), size(B, 2))))
Ac_mul_B{T}(A::DistSparseMatrix{T}, B::DistMultiVec{T}) = Ac_mul_B!(one(T), A, B, zero(T), similar(B, (size(A, 2), size(B, 2))))

# Spectral
svd(A::ElementalMatrix) = svd!(copy(A))
svd(A::ElementalMatrix, ctrl::SVDCtrl) = svd!(copy(A), ctrl)
svdvals(A::ElementalMatrix, ctrl::SVDCtrl) = svdvals!(copy(A), ctrl)

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

# function copy!{T}(dest::DistMatrix{T}, src::Base.VecOrMat)
#     m, n = size(src, 1), size(src, 2)
#     zeros!(dest, m, n)
#     if MPI.commRank(comm(B)) == 0
#         for j = 1:n
#             for i = 1:m
#                 queueUpdate(dest, i, j, src[i,j])
#             end
#         end
#     end
#     processQueues(dest)
#     return dest
# end

function convert{T}(::Type{Matrix{T}}, A::Base.VecOrMat{T})
    m, n = size(A, 1), size(A, 2)
    B = Matrix(T)
    resize!(B, m, n)
    Base.unsafe_copy!(pointer(B), pointer(A), m*n)
    return B
end
function convert{T}(::Type{Base.Matrix{T}}, A::Matrix{T})
    m, n = size(A)
    B = Base.Matrix{T}(m, n)
    Base.unsafe_copy!(pointer(B), pointer(A), m*n)
    return B
end

function convert{T}(::Type{DistMatrix{T}}, A::Base.VecOrMat{T})
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

function convert{T}(::Type{DistMultiVec{T}}, A::Base.VecOrMat{T})
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

function convert{T}(::Type{DistMatrix{T}}, A::DistMultiVec{T})
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

function norm(x::ElementalMatrix)
    if size(x, 2) == 1
        return nrm2(x)
    else
        return twoNorm(x)
    end
end

# Multiplication
(*){T}(A::DistMatrix{T}, B::Base.VecOrMat{T}) = A*convert(DistMatrix{T}, B)
(*){T}(A::DistMultiVec{T}, B::Base.VecOrMat{T}) = convert(DistMatrix{T}, A)*convert(DistMatrix{T}, B)
(*){T}(A::DistSparseMatrix{T}, B::Base.VecOrMat{T}) = A*convert(DistMultiVec{T}, B)
Ac_mul_B{T}(A::DistMatrix{T}, B::Base.VecOrMat{T}) = Ac_mul_B(A, convert(DistMatrix{T}, B))
Ac_mul_B{T}(A::DistMultiVec{T}, B::Base.VecOrMat{T}) = Ac_mul_B(convert(DistMatrix{T}, A), convert(DistMatrix{T}, B))
Ac_mul_B{T}(A::DistSparseMatrix{T}, B::Base.VecOrMat{T}) = Ac_mul_B(A, convert(DistMultiVec{T}, B))

