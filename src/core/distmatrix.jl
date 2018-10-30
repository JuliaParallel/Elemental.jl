mutable struct DistMatrix{T} <: ElementalMatrix{T}
	obj::Ptr{Cvoid}
    g::Grid # keep the grid around to avoid that it's freed before the matrix
end

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:ComplexF32, :c),
                    (:ComplexF64, :z))
    @eval begin

        # destructor to be used in finalizer. Don't call explicitly
        function destroy(A::DistMatrix{$elty})
            ElError(ccall(($(string("ElDistMatrixDestroy_", ext)), libEl), Cuint,
                (Ptr{Cvoid},), A.obj))
            return nothing
        end

        function DistMatrix(::Type{$elty}, colDist::Dist = MC, rowDist::Dist = MR, grid::Grid = DefaultGrid[])
            obj = Ref{Ptr{Cvoid}}(C_NULL)
            ElError(ccall(($(string("ElDistMatrixCreateSpecific_", ext)), libEl), Cuint,
                (Cint, Cint, Ptr{Cvoid}, Ref{Ptr{Cvoid}}),
                colDist, rowDist, grid.obj, obj))
            A = DistMatrix{$elty}(obj[], grid)
            finalizer(destroy, A)
            return A
        end

        # Probably not necesary to have this function as we carry around a reference to the Grid.
        # function Grid(A::DistMatrix{$elty})
        #     g = Grid()
        #     ElError(ccall(($(string("ElDistMatrixGrid_", ext)), libEl), Cuint,
        #         (Ptr{Cvoid}, Ref{Ptr{Cvoid}}),
        #         A.obj, Ref{Ptr{Cvoid}}(g.obj)))
        #     return g
        # end

        function comm(A::DistMatrix{$elty})
            cm = Ref{ElComm}()
            ElError(ccall(($(string("ElDistMatrixDistComm_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, Ref{ElComm}),
                A.obj, cm))
            return cm[]
        end

        function get(A::DistMatrix{$elty}, i::Integer, j::Integer)
            rv = Ref{$elty}(0)
            ElError(ccall(($(string("ElDistMatrixGet_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, ElInt, ElInt, Ref{$elty}),
                A.obj, i - 1, j - 1, rv))
            return rv[]
        end

        function getLocal(A::DistMatrix{$elty}, i::Integer, j::Integer)
            rv = Ref{$elty}(0)
            ElError(ccall(($(string("ElDistMatrixGetLocal_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, ElInt, ElInt, Ref{$elty}),
                A.obj, i - 1, j - 1, rv))
            return rv[]
        end

        function globalCol(A::DistMatrix{$elty}, i::Integer)
            rv = Ref{ElInt}(0)
            ElError(ccall(($(string("ElDistMatrixGlobalCol_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, ElInt, Ref{ElInt}),
                A.obj, i - 1, rv))
            return rv[] + 1
        end

        function globalRow(A::DistMatrix{$elty}, i::Integer)
            rv = Ref{ElInt}(0)
            ElError(ccall(($(string("ElDistMatrixGlobalRow_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, ElInt, Ref{ElInt}),
                A.obj, i - 1, rv))
            return rv[] + 1
        end

        function height(A::DistMatrix{$elty})
            rv = Ref{ElInt}(0)
            ElError(ccall(($(string("ElDistMatrixHeight_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, Ref{ElInt}),
                A.obj, rv))
            return rv[]
        end

        function localHeight(A::DistMatrix{$elty})
            rv = Ref{ElInt}(0)
            ElError(ccall(($(string("ElDistMatrixLocalHeight_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, Ref{ElInt}),
                A.obj, rv))
            return rv[]
        end

        function localWidth(A::DistMatrix{$elty})
            rv = Ref{ElInt}(0)
            ElError(ccall(($(string("ElDistMatrixLocalWidth_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, Ref{ElInt}),
                A.obj, rv))
            return rv[]
        end

        function processPullQueue(A::DistMatrix{$elty}, buf::Array{$elty,2})
            ElError(ccall(($(string("ElDistMatrixProcessPullQueue_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, Ptr{$elty}),
                A.obj, buf))
            return buf
        end

        function processQueues(A::DistMatrix{$elty})
            ElError(ccall(($(string("ElDistMatrixProcessQueues_", ext)), libEl), Cuint,
                (Ptr{Cvoid},), A.obj))
            return A
        end

        function queuePull(A::DistMatrix{$elty}, i::Integer, j::Integer)
            ElError(ccall(($(string("ElDistMatrixQueuePull_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, ElInt, ElInt),
                A.obj, i - 1, j - 1))
            return nothing
        end

        function queueUpdate(A::DistMatrix{$elty}, i::Integer, j::Integer, value::$elty)
            ElError(ccall(($(string("ElDistMatrixQueueUpdate_", ext)), libEl), Cuint,
              (Ptr{Cvoid}, ElInt, ElInt, $elty),
              A.obj, i - 1, j - 1, value))
            return nothing
        end

        function reserve(A::DistMatrix{$elty}, numEntries::Integer)
            ElError(ccall(($(string("ElDistMatrixReserve_", ext)), libEl), Cuint,
              (Ptr{Cvoid}, ElInt),
              A.obj, numEntries))
            return nothing
        end

        function width(A::DistMatrix{$elty})
            rv = Ref{ElInt}(0)
            ElError(ccall(($(string("ElDistMatrixWidth_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, Ref{ElInt}),
                A.obj, rv))
            return rv[]
        end

        function resize!(A::DistMatrix{$elty}, i::Integer, j::Integer = 1) # to mimic vector behavior
            ElError(ccall(($(string("ElDistMatrixResize_", ext)), libEl), Cuint,
                (Ptr{Cvoid}, ElInt, ElInt),
                A.obj, i, j))
            return A
        end
    end
end

DistMatrix() = DistMatrix(Float64)

#########################
### Julia convenience ###
#########################

# Do I want to provide this function? It's an invitation to be slow
getindex(A::DistMatrix, i::Integer, j::Integer) = get(A, i, j)

# This might be wrong. Should consider how to extract distributions properties of A
function similar(::DistMatrix, ::Type{T}, sz::Dims) where {T}
    A = DistMatrix(T)
    resize!(A, sz...)
    return A
end

function getindex(A::DistMatrix, iInd::Colon, jInd::UnitRange)
    B = DistMatrix(eltype(A))
    zeros!(B, size(A, 1), length(jInd))
    for j = jInd
        for i = 1:size(A, 1)
            queueUpdate(B, i, j, A[i,j])
        end
    end
    processQueues(B)
    return B
end

# FixMe! Should this one handle vectors of matrices?
function hcat(x::Vector{DistMatrix{T}}) where {T}
    l    = length(x)
    if l == 0
        throw(ArgumentError("cannot flatten empty vector"))
    else
        x1   = x[1]
        m, n = size(x1, 1), size(x1, 2)
        if n != 1
            throw(ArgumentError("elements have to be vectors, i.e. the second dimension has to have size one"))
        end
        A    = DistMatrix(T)
        zeros!(A, m, l*n)
        for j = 1:l
            xj = x[j]
            for k = 1:localWidth(xj)
                for i = 1:localHeight(xj)
                    xji = getLocal(xj, i, 1)
                    queueUpdate(A, globalRow(xj, i), j, xji)
                end
            end
        end
        processQueues(A)
        return A
    end
end
