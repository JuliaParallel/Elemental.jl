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

(*){T<:ElementalMatrix}(A::T, B::T) = A_mul_B!(1.0, A, B, 0.0, similar(A, (size(A, 1), size(B, 2))))

# Spectral
svd(A::ElementalMatrix) = svd!(copy(A))