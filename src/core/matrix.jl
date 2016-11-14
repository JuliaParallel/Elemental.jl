type Matrix{T} <: ElementalMatrix{T}
    obj::Ptr{Void}
end

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin

        # destructor to be used in finalizer. Don't call explicitly
        function destroy(A::Matrix{$elty})
            err = ccall(($(string("ElMatrixDestroy_", ext)), libEl), Cuint,
                (Ptr{Void},), A.obj)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function Matrix(::Type{$elty})
            obj = Ref{Ptr{Void}}(0)
            err = ccall(($(string("ElMatrixCreate_", ext)), libEl), Cuint,
                (Ref{Ptr{Void}},), obj)
            err == 0 || throw(ElError(err))
            A = Matrix{$elty}(obj[])
            finalizer(A, destroy)
            return A
        end

        function getindex(A::Matrix{$elty}, i::Integer, j::Integer)
            x = Ref{$elty}(0)
            err = ccall(($(string("ElMatrixGet_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, Ref{$elty}),
                A.obj, i - 1, j - 1, x)
            err == 0 || throw(ElError(err))
            return x[]
        end

        function resize!(A::Matrix{$elty}, i::Integer, j::Integer = 1) # to mimic vector behavior
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

        function setindex!(A::Matrix{$elty}, x::Number, i::Integer, j::Integer)
            err = ccall(($(string("ElMatrixSet_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty),
                A.obj, i - 1, j - 1, x)
            err == 0 || throw(ElError(err))
            return A
        end
    end
end

Matrix() = Matrix(Float64)

# Julia convenience

pointer(A::Matrix) = lockedBuffer(A)

function similar{T}(::Matrix, ::Type{T}, sz::Dims)
    A = Matrix(T)
    resize!(A, sz...)
    return A
end

countnz(A::Matrix) = length(A)
