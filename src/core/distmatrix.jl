type DistMatrix{T} <: ElementalMatrix{T}
	obj::Ptr{Void}
end

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function DistMatrix(::Type{$elty}, colDist = MC, rowDist = MR, grid = Grid())
            obj = Ref{Ptr{Void}}(C_NULL)
            err = ccall(($(string("ElDistMatrixCreateSpecific_", ext)), libEl), Cuint,
                (Cint, Cint, Ptr{Void}, Ref{Ptr{Void}}),
                colDist, rowDist, grid.obj, obj)
            err == 0 || throw(ElError(err))
            return DistMatrix{$elty}(obj[])
        end
    end
end

DistMatrix() = DistMatrix(Float64)

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function Grid(A::DistMatrix{$elty})
            g = Grid()
            err = ccall(($(string("ElDistMatrixGrid_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{Ptr{Void}}),
                A.obj, Ref{Ptr{Void}}(g.obj))
            err == 0 || throw(ElError(err))
            return g
        end

        function height(A::DistMatrix{$elty})
            rv = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, rv)
            err == 0 || throw(ElError(err))
            return rv[]
        end

        function width(A::DistMatrix{$elty})
            rv = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixWidth_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, rv)
            err == 0 || throw(ElError(err))
            return rv[]
        end

        function reserve(A::DistMatrix{$elty}, numEntries::Integer)
            err = ccall(($(string("ElDistMatrixReserve_", ext)), libEl), Cuint,
              (Ptr{Void}, ElInt),
              A.obj, numEntries)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function queueUpdate(A::DistMatrix{$elty}, i::Integer, j::Integer, value::$elty)
            err = ccall(($(string("ElDistMatrixQueueUpdate_", ext)), libEl), Cuint,
              (Ptr{Void}, ElInt, ElInt, $elty),
              A.obj, i - 1, j - 1, value)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function processQueues(A::DistMatrix{$elty})
            err = ccall(($(string("ElDistMatrixProcessQueues_", ext)), libEl), Cuint,
                (Ptr{Void},), A.obj)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function queuePull(A::DistMatrix{$elty}, i::Integer, j::Integer)
            err = ccall(($(string("ElDistMatrixQueuePull_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt),
                A.obj, i - 1, j - 1)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function processPullQueue(A::DistMatrix{$elty}, buf::Array{$elty,2})
            err = ccall(($(string("ElDistMatrixProcessPullQueue_", ext)), libEl), Cuint,
                (Ptr{Void}, Ptr{$elty}),
                A.obj, buf)
            err == 0 || throw(ElError(err))
            return buf
        end

        function getindex(A::DistMatrix{$elty}, i::Integer, j::Integer)
            rv = Ref{$elty}(0)
            err = ccall(($(string("ElDistMatrixGet_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, Ref{$elty}),
                A.obj, i - 1, j - 1, rv)
            err == 0 || throw(ElError(err))
            return rv[]
        end

        function resize!(A::DistMatrix{$elty}, i::Integer, j::Integer)
            err = ccall(($(string("ElDistMatrixResize_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt),
                A.obj, i, j)
            err == 0 || throw(ElError(err))
            return A
        end
    end
end

countnz(A::DistMatrix) = length(A)

# This might be wrong. Should consider how to extract distributions properties of A
similar(A::DistMatrix) = similar(A, size(A))
similar{T}(A::DistMatrix{T}, sz::Tuple{Int,}) = similar(A, (sz[1],1))
function similar{T}(A::DistMatrix{T}, sz::Tuple{Int,Int})
    B = DistMatrix(T)
    resize!(B, sz...)
    return B
end
