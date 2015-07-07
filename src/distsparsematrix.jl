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
                A.obj, iLoc-1, i)
            err == 0 || throw(ElError(err))
            return i[]+1
        end

        function queueLocalUpdate{$elty}(A::DistSparseMatrix{$elty}, localRow::Integer, col::Integer, value::$elty)
            err = ccall(($(string("ElDistSparseMatrixQueueLocalUpdate_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty),
                A.obj, localRow-1, col-1, value)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function queueUpdate{$elty}(A::DistSparseMatrix{$elty}, row::Integer, col::Integer, value::$elty, passive::Bool = true)
            err = ccall(($(string("ElDistSparseMatrixQueueUpdate_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty, Bool),
                A.obj, row-1, col-1, value, passive)
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

        # It is assumed that the DArray is distributed over MPI.COMM_WORLD
        function DistSparseMatrix(::Type{$elty}, DA::DistributedArrays.DArray)
            npr, npc = size(procs(DA))
            if npr*npc != MPI.Comm_size(MPI.COMM_WORLD)
              error("Used non MPI.COMM_WORLD DArray for DistSparseMatrix, as procs(DA)=($npr,$npc) is incompatible with MPI.Comm_size(MPI.COMM_WORLD)=$(MPI.Comm_size(MPI.COMM_WORLD))")
            end

            m, n = size(DA) 
            A = DistSparseMatrix($elty, m, n)
            @sync begin 
                for id in workers()
                  let A = A, DA = DA
                    @async remotecall_fetch(id, () -> begin
                      rows, cols = DistributedArrays.localindexes(DA)
                      i,j,v = findnz(DistributedArrays.localpart(DA))
                      gi, gj, gv = (i.+(first(rows)-1), j.+(first(cols)-1), v) 
                      numLocal = length(gi)
                      reserve(A,numLocal) 
                      for s=1:numLocal
                        queueUpdate(A,gi[s],gj[s],v[s])
                      end
                    end)
                  end
                end
            end
            processQueues(A)
            return A
        end
    end
end

size(A::DistSparseMatrix) = (Int(height(A)), Int(width(A)))
