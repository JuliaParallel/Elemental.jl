type DistSparseMatrix{T} <: ElementalMatrix{T}
    obj::Ptr{Void}
end

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function DistSparseMatrix(::Type{$elty}, cm::ElComm)
            obj = Ref{Ptr{Void}}(C_NULL)
            err = ccall(($(string("ElDistSparseMatrixCreate_", ext)), libEl), Cuint,
                (Ref{Ptr{Void}}, ElComm),
                obj, cm)
            err == 0 || throw(ElError(err))
            return DistSparseMatrix{$elty}(obj[])
        end

        function DistSparseMatrix(::Type{$elty}, cm::MPI.Comm = MPI.COMM_WORLD)
            cComm = Ref{ElComm}()
            err = ccall((:ElMPICommF2C, libEl), Cuint,
              (Cint, Ref{ElComm}),
              cm.val,cComm)
            err == 0 || throw(ElError(err))

            return DistSparseMatrix($elty, cComm[])
        end

        function DistSparseMatrix(::Type{$elty}, m::Integer, n::Integer, comm = MPI.COMM_WORLD)
            A = DistSparseMatrix($elty, comm)
            resize(A, m, n)
            return A
        end

        function destroy(A::DistSparseMatrix)
            err = ccall(($(string("ElDistSparseMatrixDestroy_", ext)), libEl), Cuint,
                (Ptr{Void},),
                A.obj)
            err == 0 || throw(ElError(err))
            return 0
        end

        function resize{$elty}(A::DistSparseMatrix{$elty}, height::Integer, width::Integer)
            err = ccall(($(string("ElDistSparseMatrixResize_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt),
                A.obj, height, width)
            err == 0 || throw(ElError(err))
            return A
        end

        function localHeight{$elty}(A::DistSparseMatrix{$elty})
            i = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixLocalHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, i)
            err == 0 || throw(ElError(err))
            return i[]
        end

        function reserve{$elty}(A::DistSparseMatrix{$elty}, numLocalEntries::Integer, numRemoteEntries::Integer = 0)
            err = ccall(($(string("ElDistSparseMatrixReserve_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt),
                A.obj, numLocalEntries, numRemoteEntries)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function globalRow{$elty}(A::DistSparseMatrix{$elty}, iLoc::Integer)
            i = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixGlobalRow_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, Ref{ElInt}),
                A.obj, iLoc, i)
            err == 0 || throw(ElError(err))
            return i[]
        end

        function queueLocalUpdate{$elty}(A::DistSparseMatrix{$elty}, localRow::Integer, col::Integer, value::$elty)
            err = ccall(($(string("ElDistSparseMatrixQueueLocalUpdate_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty),
                A.obj, localRow, col, value)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function queueUpdate{$elty}(A::DistSparseMatrix{$elty}, row::Integer, col::Integer, value::$elty, passive::Bool = true)
            err = ccall(($(string("ElDistSparseMatrixQueueUpdate_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty, Bool),
                A.obj, row, col, value, passive)
            err == 0 || error("something is wrong here!")
            return nothing
        end

        function processQueues{$elty}(A::DistSparseMatrix{$elty})
            err = ccall(($(string("ElDistSparseMatrixProcessQueues_", ext)), libEl), Cuint,
                (Ptr{Void},),
                A.obj)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function height{$elty}(A::DistSparseMatrix{$elty})
            i = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, i)
            err == 0 || throw(ElError(err))
            return i[]
        end

        function width{$elty}(A::DistSparseMatrix{$elty})
            i = Ref{ElInt}(0)
            err = ccall(($(string("ElDistSparseMatrixWidth_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, i)
            err == 0 || throw(ElError(err))
            return i[]
        end

        function comm(A::DistSparseMatrix{$elty})
            cm = Ref{ElComm}()
            err = ccall(($(string("ElDistSparseMatrixComm_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElComm}),
                A.obj, cm)
            err == 0 || throw(ElError(err))
            return cm[]
        end
    end
end

size(A::DistSparseMatrix) = (Int(height(A)), Int(width(A)))
