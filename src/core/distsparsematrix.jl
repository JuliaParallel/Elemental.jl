type DistSparseMatrix{T} <: ElementalMatrix{T}
    obj::Ptr{Void}
end

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin

        # destructor to be used in finalizer. Don't call explicitly
        function destroy(A::DistSparseMatrix{$elty})
            ElError(ccall(($(string("ElDistSparseMatrixDestroy_", ext)), libEl), Cuint,
                (Ptr{Void},), A.obj))
            return nothing
        end

        function DistSparseMatrix(::Type{$elty}, comm::ElComm = CommWorld)
            obj = Ref{Ptr{Void}}(C_NULL)
            ElError(ccall(($(string("ElDistSparseMatrixCreate_", ext)), libEl), Cuint,
                (Ref{Ptr{Void}}, ElComm),
                obj, comm))
            A = DistSparseMatrix{$elty}(obj[])
            finalizer(A, destroy)
            return A
        end

        function comm(A::DistSparseMatrix{$elty})
            cm = Ref{ElComm}()
            ElError(ccall(($(string("ElDistSparseMatrixComm_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElComm}),
                A.obj, cm))
            return cm[]
        end

        function globalRow(A::DistSparseMatrix{$elty}, iLoc::Integer)
            i = Ref{ElInt}(0)
            ElError(ccall(($(string("ElDistSparseMatrixGlobalRow_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, Ref{ElInt}),
                A.obj, iLoc-1, i))
            return i[]+1
        end

        function height(A::DistSparseMatrix{$elty})
            i = Ref{ElInt}(0)
            ElError(ccall(($(string("ElDistSparseMatrixHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, i))
            return i[]
        end

        function localHeight(A::DistSparseMatrix{$elty})
            i = Ref{ElInt}(0)
            ElError(ccall(($(string("ElDistSparseMatrixLocalHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, i))
            return i[]
        end

        function numLocalEntries(A::DistSparseMatrix{$elty})
            n = Ref{ElInt}(0)
            ElError(ccall(($(string("ElDistSparseMatrixNumLocalEntries_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, n))
            return n[]
        end

        function processQueues(A::DistSparseMatrix{$elty})
            ElError(ccall(($(string("ElDistSparseMatrixProcessQueues_", ext)), libEl), Cuint,
                (Ptr{Void},),
                A.obj))
            return nothing
        end

        function queueLocalUpdate(A::DistSparseMatrix{$elty}, localRow::Integer, col::Integer, value::$elty)
            ElError(ccall(($(string("ElDistSparseMatrixQueueLocalUpdate_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty),
                A.obj, localRow-1, col-1, value))
            return nothing
        end

        function queueUpdate(A::DistSparseMatrix{$elty}, row::Integer, col::Integer, value::$elty, passive::Bool = true)
            ElError(ccall(($(string("ElDistSparseMatrixQueueUpdate_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty, Bool),
                A.obj, row-1, col-1, value, passive))
            return nothing
        end

        function reserve(A::DistSparseMatrix{$elty}, numLocalEntries::Integer, numRemoteEntries::Integer = 0)
            ElError(ccall(($(string("ElDistSparseMatrixReserve_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt),
                A.obj, numLocalEntries, numRemoteEntries))
            return nothing
        end

        function resize!(A::DistSparseMatrix{$elty}, height::Integer, width::Integer = 1) # to mimic vector behavior
            ElError(ccall(($(string("ElDistSparseMatrixResize_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt),
                A.obj, height, width))
            return A
        end

        function width(A::DistSparseMatrix{$elty})
            i = Ref{ElInt}(0)
            ElError(ccall(($(string("ElDistSparseMatrixWidth_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, i))
            return i[]
        end
    end
end

# The other constructors don't have a version with dimensions. Should they, or should this one go?
function DistSparseMatrix{T}(::Type{T}, m::Integer, n::Integer, comm::ElComm = CommWorld)
    A = DistSparseMatrix(T, comm)
    resize!(A, m, n)
    return A
end

# Julia convenience

countnz(A::DistSparseMatrix) = MPI.allreduce(Cint(numLocalEntries(A)), +, comm(A))

function showarray(io::IO, A::DistSparseMatrix; kwargs...)
    print(io, "$(size(A, 1))x$(size(A, 2)) $(typeof(A))")
end
