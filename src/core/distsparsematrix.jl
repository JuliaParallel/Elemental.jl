type DistSparseMatrix{T} <: ElementalMatrix{T}
    obj::Ptr{Void}
end

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function DistSparseMatrix(::Type{$elty}, comm::ElComm = CommWorld)
            obj = Ref{Ptr{Void}}(C_NULL)
            err = ccall(($(string("ElDistSparseMatrixCreate_", ext)), libEl), Cuint,
                (Ref{Ptr{Void}}, ElComm),
                obj, comm)
            err == 0 || throw(ElError(err))
            return DistSparseMatrix{$elty}(obj[])
        end

        function comm(A::DistSparseMatrix{$elty})
            cm = Ref{ElComm}()
            err = ccall(($(string("ElDistSparseMatrixComm_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElComm}),
                A.obj, cm)
            err == 0 || throw(ElError(err))
            return cm[]
        end

        function destroy(A::DistSparseMatrix{$elty})
            err = ccall(($(string("ElDistSparseMatrixDestroy_", ext)), libEl), Cuint,
                (Ptr{Void},),
                A.obj)
            err == 0 || throw(ElError(err))
            return 0
        end

        function globalRow(A::DistSparseMatrix{$elty}, iLoc::Integer)
            i = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixGlobalRow_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, Ref{ElInt}),
                A.obj, iLoc-1, i)
            err == 0 || throw(ElError(err))
            return i[]+1
        end

        function height(A::DistSparseMatrix{$elty})
            i = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, i)
            err == 0 || throw(ElError(err))
            return i[]
        end

        function localHeight(A::DistSparseMatrix{$elty})
            i = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixLocalHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, i)
            err == 0 || throw(ElError(err))
            return i[]
        end

        function numLocalEntries(A::DistSparseMatrix{$elty})
            n = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixNumLocalEntries_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, n)
            err == 0 || throw(ElError(err))
            return n[]
        end

        function processQueues(A::DistSparseMatrix{$elty})
            err = ccall(($(string("ElDistSparseMatrixProcessQueues_", ext)), libEl), Cuint,
                (Ptr{Void},),
                A.obj)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function queueLocalUpdate(A::DistSparseMatrix{$elty}, localRow::Integer, col::Integer, value::$elty)
            err = ccall(($(string("ElDistSparseMatrixQueueLocalUpdate_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty),
                A.obj, localRow-1, col-1, value)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function queueUpdate(A::DistSparseMatrix{$elty}, row::Integer, col::Integer, value::$elty, passive::Bool = true)
            err = ccall(($(string("ElDistSparseMatrixQueueUpdate_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty, Bool),
                A.obj, row-1, col-1, value, passive)
            err == 0 || error("something is wrong here!")
            return nothing
        end

        function reserve(A::DistSparseMatrix{$elty}, numLocalEntries::Integer, numRemoteEntries::Integer = 0)
            err = ccall(($(string("ElDistSparseMatrixReserve_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt),
                A.obj, numLocalEntries, numRemoteEntries)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function resize!(A::DistSparseMatrix{$elty}, height::Integer, width::Integer = 1) # to mimic vector behavior
            err = ccall(($(string("ElDistSparseMatrixResize_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt),
                A.obj, height, width)
            err == 0 || throw(ElError(err))
            return A
        end

        function width(A::DistSparseMatrix{$elty})
            i = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixWidth_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, i)
            err == 0 || throw(ElError(err))
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
