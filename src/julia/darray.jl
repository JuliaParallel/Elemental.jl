# FixMe! Right now the MPI workers are deduced from the DArrays, but if a DArray is distributed on fewer workers that what consistutes the MPI world, then this approach will fail.

using DistributedArrays: procs

mutable struct RemoteElementalMatrix
    refs::Matrix{Any}
end

function toback(A::DArray{T,2,S}) where {T<:BlasFloat,S<:StridedMatrix}
    rs = Array{Any}(undef, size(procs(A)))
    @sync for p in eachindex(procs(A))
        ind = A.indices[p]
        @async rs[p] = remotecall(procs(A)[p]) do
            lA = localpart(A)
            AlA = Elemental.DistMatrix(T)
            zeros!(AlA, size(A)...)
            for j = 1:size(lA,2), i = 1:size(lA, 1)
                queueUpdate(AlA,
                            first(ind[1]) + i - 1,
                            first(ind[2]) + j - 1, lA[i,j])
            end
            processQueues(AlA)
            AlA
        end
    end
    return rs
end

function tofront(r::Base.Matrix)
    tt = Array{Any}(undef, length(r))
    for i = 1:length(r)
        tt[i] = remotecall(r[i].where, r[i]) do t
            typeof(fetch(t))
        end
    end

    rType = fetch(tt[1])
    if rType <: ElementalMatrix
        for i = 1:length(r)
            tt[i] = remotecall(r[i].where, r[i]) do t
                v = fetch(t)
                (size(v), eltype(v))
            end
        end
        sizeAndEltype = fetch(tt[1])
        if isa(sizeAndEltype, Exception)
            throw(sizeAndEltype)
        end

        mn = sizeAndEltype[1]
        A = dzeros(sizeAndEltype[2], mn,
                   Int[r[i].where for i in eachindex(r)])

        @sync for p in eachindex(r)
            ind = A.indices[p]
            rr = r[p]
            @async remotecall_wait(r[p].where) do
                rrr = fetch(rr)
                lA = localpart(A)
                for j = 1:size(lA, 2), i = 1:size(lA, 1)
                    queuePull(rrr,
                              first(ind[1]) + i - 1,
                              first(ind[2]) + j - 1)
                end
                processPullQueue(rrr, lA)
            end
        end
    elseif rType <: Exception
        throw(fetch(r[1]))
    else
        error("Remote type was $rType and is not handled yet")
    end
    return A
end

function (\)(A::DArray{T,2,S}, B::DArray{T,2,S}) where {T<:BlasFloat,S}
    rA = toback(A)
    rB = toback(B)
    pidsAB = union(A.pids, B.pids)
    rvals = Vector{Any}(undef, length(pidsAB))
    @sync for i = 1:length(pidsAB)
        @async rvals[i] = remotecall_wait(pidsAB[i], rA[i], rB[i]) do t1,t2
            solve!(fetch(t1), fetch(t2))
        end
    end
    return tofront(reshape(rvals, size(procs(B))))
end

function LinearAlgebra.eigvals(A::Hermitian{T,DArray{T,2,Array{T,2}}} where {T<:BlasFloat} )
    rA = toback(A.data)
    rvals = Array{Any}(undef, size(procs(A.data)))
    uplo = A.uplo == 'U' ? UPPER : LOWER
    @sync for i in eachindex(rvals)
        @async rvals[i] = remotecall_wait(rA[i].where, rA[i]) do t
            eigvalsHermitian(uplo, fetch(t))
        end
    end
    return tofront(rvals)
end

function LinearAlgebra.svdvals(A::DArray{<:BlasFloat,2})
    rA = toback(A)
    rvals = Array{Any}(undef, size(procs(A)))
    @sync for i in eachindex(rvals)
        @async rvals[i] = remotecall_wait(rA[i].where, rA[i]) do t
            svdvals(fetch(t))
        end
    end
    return tofront(rvals)
end

function LinearAlgebra.inv!(A::DArray{<:BlasFloat,2})
    rA = toback(A)
    rvals = Array{Any}(undef, size(procs(A)))
    @sync for j = 1:size(rvals, 2)
        for i = 1:size(rvals, 1)
            @async rvals[i,j] = remotecall_wait(t -> inverse!(fetch(t)), rA[i,j].where, rA[i,j])
        end
    end
    return tofront(rvals)
end

LinearAlgebra.inv(A::DArray{<:BlasFloat,2}) = LinearAlgebra.inv!(copy(A))

function LinearAlgebra.logdet(A::DArray{<:BlasFloat,2})
    rA = toback(A)
    rvals = Array{Any}(undef, size(procs(A)))
    @sync for i in eachindex(rvals)
        @async rvals[i] = remotecall_wait(rA[i].where, rA[i]) do t
            d = safeHPDDeterminant(Elemental.LOWER, fetch(t))
            return log(d.ρ) + d.κ*d.n
        end
    end
    return fetch(rvals[1])
end

function spectralPortrait(A::DArray{T,2},
                          realSize::Integer,
                          imagSize::Integer,
                          psCtrl::PseudospecCtrl{T}=PseudospecCtrl(T)) where {T<:BlasReal}
    rA = toback(A)
    rvals = Array{Any}(undef, size(procs(A)))
    @sync for i in eachindex(rvals)
        @async rvals[i] = remotecall_wait(rA[i].where, rA[i]) do t
            spectralPortrait(fetch(t), ElInt(realSize), ElInt(imagSize), psCtrl)[1]
        end
    end
    return tofront(rvals)
end

function spectralPortrait(A::DArray{Complex{T},2},
                          realSize::Integer,
                          imagSize::Integer,
                          psCtrl::PseudospecCtrl{T}=PseudospecCtrl(T)) where {T<:BlasReal}
    rA = toback(A)
    rvals = Array{Any}(undef, size(procs(A)))
    @sync for i in eachindex(rvals)
        @async rvals[i,j] = remotecall_wait(rA[i].where, rA[i]) do t
            spectralPortrait(fetch(t), ElInt(realSize), ElInt(imagSize), psCtrl)[1]
        end
    end
    return tofront(rvals)
end

function spectralWindow(A::DArray{T,2},
                        center::Complex{T},
                        realWidth::T,
                        imagWidth::T,
                        realSize::Integer,
                        imagSize::Integer,
                        psCtrl::PseudospecCtrl{T}=PseudospecCtrl(T)) where {T<:BlasReal}
    rA = toback(A)
    rvals = Array{Any}(undef, size(procs(A)))
    @sync for i in eachindex(rvals)
        @async rvals[i] = remotecall_wait(rA[i].where, rA[i]) do t
            spectralWindow(fetch(t), center, realWidth, imagWidth,
                           ElInt(realSize), ElInt(imagSize), psCtrl)
        end
    end
    return tofront(rvals)
end

function spectralWindow(A::DArray{Complex{T},2},
                        center::Complex{T},
                        realWidth::T,
                        imagWidth::T,
                        realSize::Integer,
                        imagSize::Integer,
                        psCtrl::PseudospecCtrl{T}=PseudospecCtrl(T)) where {T<:BlasReal}
    rA = toback(A)
    rvals = Array{Any}(undef, size(procs(A)))
    @sync for i in eachindex(rvals)
        @async rvals[i] = remotecall_wait(rA[i,j].where, rA[i]) do t
            spectralWindow(fetch(t), center, realWidth, imagWidth,
                           ElInt(realSize), ElInt(imagSize), psCtrl)
        end
    end
    return tofront(rvals)
end

function foxLi(::Type{T}, n::Integer, ω::Real) where {T<:BlasComplex}
    sz = tuple(DistributedArrays.defaultdist((n,n), workers())...)
    rvals = Array{Any}(undef, sz)
    @sync for j = 1:size(rvals, 2), i = 1:size(rvals, 1)
        @async rvals[i,j] = remotecall_wait(workers()[sub2ind(sz, i, j)]) do
            A = Elemental.DistMatrix(T)
            foxLi!(A, ElInt(n), real(T)(ω))
        end
    end
    return tofront(rvals)
end
foxLi(n::Integer, ω::Real) = foxLi(ComplexF64, n, ω)

# Andreas: Just saw this one. It is almost identical to the one I wrote above,
# but I don't think that we can return a Elemental array beacause it has to
# live on the MPI cluster and cannot live on the "front end".
# It is assumed that the DArray is distributed over MPI.COMM_WORLD
for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:ComplexF32, :c),
                    (:ComplexF64, :z))
    @eval begin
        function convert(::Type{DistSparseMatrix{$elty}}, DA::DistributedArrays.DArray)
            npr, npc = size(procs(DA))
            if npr*npc != MPI.Comm_size(MPI.COMM_WORLD)
                error("Used non MPI.COMM_WORLD DArray for DistSparseMatrix, ",
                      "as procs(DA)=($npr,$npc) is incompatible with ",
                      "MPI.Comm_size(MPI.COMM_WORLD)=$(MPI.Comm_size(MPI.COMM_WORLD))")
            end

            m, n = size(DA)
            A = DistSparseMatrix($elty, m, n)
            @sync begin
                for id in workers()
                    let A = A, DA = DA
                        @async remotecall_fetch(id) do
                            rows, cols = DistributedArrays.localindices(DA)
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

        function convert(::Type{DistMatrix{$elty}}, DA::DistributedArrays.DArray)
            npr, npc = size(procs(DA))
            if npr*npc != MPI.Comm_size(MPI.COMM_WORLD)
                error("Used non MPI.COMM_WORLD DArray for DistMatrix, ",
                      "as procs(DA)=($npr,$npc) is incompatible with ",
                      "MPI.Comm_size(MPI.COMM_WORLD)=$(MPI.Comm_size(MPI.COMM_WORLD))")
            end

            m, n = size(DA)
            A = DistMatrix($elty, m, n)
            @sync begin
                for id in workers()
                    let A = A, DA = DA
                        @async remotecall_fetch(id) do
                            rows, cols = DistributedArrays.localindices(DA)
                            reserve(A,length(rows) * length(cols))
                            for j in cols, i in rows
                              queueUpdate(A, i - 1, j - 1, DA[i, j])
                            end
                        end
                    end
                end
            end
            processQueues(A)
            return A
        end

        function copyto!(DA::DistributedArrays.DArray{$elty}, A::DistMatrix{$elty} )
            @sync begin
              ijs = localindices(DA)
              for j in ijs[2], i in ijs[1]
                  queuePull(A, i, j)
              end
              DAlocal = DA[:L]

              DAlocal_mat = ndims(DAlocal) == 1 ? reshape(DAlocal, :, 1) : DAlocal
              processPullQueue(A, DAlocal_mat)
            end
            return DA
        end
    end
end
