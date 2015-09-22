type Matrix{T} <: ElementalMatrix{T}
    obj::Ptr{Void}
end

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function Matrix(::Type{$elty})
            obj = Ref{Ptr{Void}}(0)
            err = ccall(($(string("ElMatrixCreate_", ext)), libEl), Cuint,
                (Ref{Ptr{Void}},), obj)
            err == 0 || throw(ElError(err))
            return Matrix{$elty}(obj[])
        end

        function resize!(A::Matrix{$elty}, i::Integer, j::Integer)
            err = ccall(($(string("ElMatrixResize_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt),
                A.obj, i, j)
            err == 0 || throw(ElError(err))
            return A
        end

        function height(A::Matrix{$elty})
            rs = Ref{ElInt}(0)
            err = ccall(($(string("ElMatrixHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
            A.obj, rs)
            err == 0 || throw(ElError(err))
            return rs[]
        end

        function width(A::Matrix{$elty})
            rs = Ref{ElInt}(0)
            err = ccall(($(string("ElMatrixWidth_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
            A.obj, rs)
            err == 0 || throw(ElError(err))
            return rs[]
        end

        function lockedBuffer(A::Matrix{$elty})
            rp = Ref{Ptr{$elty}}(0)
            err = ccall(($(string("ElMatrixLockedBuffer_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{Ptr{$elty}}),
                A.obj, rp)
            err == 0 || throw(ElError(err))
            return rp[]
        end
    end

end

# Julia convenience

function getindex(A::Matrix, i::Integer, j::Integer)
    m, n = size(A)
    p = lockedBuffer(A)
    li = j + n*(i - 1)
    if i < 1 || j < 1 || li > m*n
        throw(BoundsError(A, (i,j)))
    end
    return unsafe_load(p, li)
end

function setindex!(A::Matrix, x::Number, i::Integer, j::Integer)
    m, n = size(A)
    p = lockedBuffer(A)
    li = j + n*(i - 1)
    if i < 1 || j < 1 || li > m*n
        throw(BoundsError(A, (i,j)))
    end
    return unsafe_store!(p, x, li)
end

function similar{T}(A::Matrix{T})
    B = Matrix(T)
    resize!(B, size(A)...)
    return B
end

function size(A::Matrix, i::Integer)
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
size(A::Matrix) = (size(A, 1), size(A, 2))
