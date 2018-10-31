mutable struct Matrix{T} <: ElementalMatrix{T}
    obj::Ptr{Cvoid}
end

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:ComplexF32, :c),
                    (:ComplexF64, :z))
    @eval begin

        # destructor to be used in finalizer. Don't call explicitly
        function destroy(A::Matrix{$elty})
            ElError(ccall(($(string("ElMatrixDestroy_", ext)), libEl), Cuint,
                (Ptr{Cvoid},), A.obj))
            return nothing
        end

        function Matrix(::Type{$elty})
            obj = Ref{Ptr{Cvoid}}(0)
            ElError(ccall(($(string("ElMatrixCreate_", ext)), libEl), Cuint,
                (Ref{Ptr{Cvoid}},), obj))
            A = Matrix{$elty}(obj[])
            finalizer(destroy, A)
            return A
        end

        function getindex(A::Matrix{$elty}, i::Integer, j::Integer)
            x = Ref{$elty}(0)
            ElError(ccall(($(string("ElMatrixGet_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, ElInt, ElInt, Ref{$elty}),
                A.obj, i - 1, j - 1, x))
            return x[]
        end

        function resize!(A::Matrix{$elty}, i::Integer, j::Integer = 1) # to mimic vector behavior
            ElError(ccall(($(string("ElMatrixResize_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, ElInt, ElInt),
                A.obj, i, j))
            return A
        end

        function height(A::Matrix{$elty})
            rs = Ref{ElInt}(0)
            ElError(ccall(($(string("ElMatrixHeight_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, Ref{ElInt}),
            A.obj, rs))
            return rs[]
        end

        function width(A::Matrix{$elty})
            rs = Ref{ElInt}(0)
            ElError(ccall(($(string("ElMatrixWidth_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, Ref{ElInt}),
            A.obj, rs))
            return rs[]
        end

        function lockedBuffer(A::Matrix{$elty})
            rp = Ref{Ptr{$elty}}(0)
            ElError(ccall(($(string("ElMatrixLockedBuffer_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, Ref{Ptr{$elty}}),
                A.obj, rp))
            return rp[]
        end

        function setindex!(A::Matrix{$elty}, x::Number, i::Integer, j::Integer)
            ElError(ccall(($(string("ElMatrixSet_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, ElInt, ElInt, $elty),
                A.obj, i - 1, j - 1, x))
            return A
        end
    end
end

Matrix() = Matrix(Float64)

# Julia convenience

pointer(A::Matrix) = lockedBuffer(A)

function similar(::Matrix, ::Type{T}, sz::Dims) where {T}
    A = Matrix(T)
    resize!(A, sz...)
    return A
end
