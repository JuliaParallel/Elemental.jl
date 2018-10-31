for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))

    for (matA, matb, sym) in ((:Matrix, :Matrix, "_"),
                              (:DistMatrix, :DistMatrix, "Dist_"),
                              (:SparseMatrix, :Matrix, "Sparse_"),
                              (:DistSparseMatrix, :DistMultiVec, "DistSparse_"))
        @eval begin

            function lav!(A::$matA{$elty}, b::$matb{$elty}, x::$matb{$elty})
                ElError(ccall(($(string("ElLAV", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                    A.obj, b.obj, x.obj))
                return x
            end

            function lav!(A::$matA{$elty}, b::$matb{$elty}, x::$matb{$elty}, ctrl::LPAffineCtrl{$elty})
                ElError(ccall(($(string("ElLAVX", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, LPAffineCtrl{$elty}),
                    A.obj, b.obj, x.obj, ctrl))
                return x
            end
        end
    end
end

function lav(A::Matrix{T}, b::Matrix{T}) where {T<:Union{Float32,Float64}}
    x = Matrix(T)
    return lav!(A, b, x)
end
function lav(A::DistMatrix{T}, b::DistMatrix{T}) where {T<:Union{Float32,Float64}}
    x = DistMatrix(T, MC, MR, A.g)
    return lav!(A, b, x)
end
function lav(A::DistSparseMatrix{T}, b::DistMultiVec{T}) where {T<:Union{Float32,Float64}}
    x = DistMultiVec(T, comm(A))
    return lav!(A, b, x)
end

function lav(A::DistSparseMatrix{T}, b::DistMultiVec{T}, ctrl::LPAffineCtrl{T}) where {T<:Union{Float32,Float64}}
    x = DistMultiVec(T, comm(A))
    return lav!(A, b, x, ctrl)
end
