using DistributedArrays

function toback{S<:StridedMatrix}(A::DArray{Float64,2,S})
    rs = Array(Any, size(A.chunks))
    for p in eachindex(A.chunks)
        ind = A.indexes[p]
        rs[p] = remotecall(A.pids[p]) do
            lA = localpart(A)
            AlA = Elemental.DistMatrix(Float64)
            zeros!(AlA, size(A)...)
            for j = 1:size(lA, 2)
                for i = 1:size(lA, 1)
                    queueUpdate(AlA, start(ind[1]) + i - 1, start(ind[2]) + j - 1, lA[i,j])
                end
            end
            processQueues(AlA)
            AlA
        end
    end
    return rs
end

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
# Andreas: Just saw this one. It is almost identical to the one I wrote above, but I don't think that we can return a Elemental array beacause it has to live on the MPI cluster and cannot live on the "front end".
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
                        @async remotecall_fetch(id) do
                            rows, cols = DistributedArrays.localindexes(DA)
                            i,j,v = findnz(DistributedArrays.localpart(DA))
                            gi, gj, gv = (i.+(first(rows)-1), j.+(first(cols)-1), v)
                            numLocal = length(gi)
                            reserve(A,numLocal)
                            for s=1:numLocal
                                queueUpdate(A,gi[s],gj[s],v[s])
                            end
                        end
                    end
                end
            end
            processQueues(A)
            return A
        end
    end
end