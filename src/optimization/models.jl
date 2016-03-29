for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))

    for (matA, matb, sym) in ((:Matrix, :Matrix, "_"),
                              (:DistMatrix, :DistMatrix, "Dist_"),
                              (:SparseMatrix, :Matrix, "Sparse_"),
                              (:DistSparseMatrix, :DistMultiVec, "DistSparse_"))
        @eval begin

            function lav!(A::$matA{$elty}, b::$matb{$elty}, x::$matb{$elty})
                err = ccall(($(string("ElLAV", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}, Ptr{Void}),
                    A.obj, b.obj, x.obj)
                err == 0 || throw(ElError(err))
                return x
            end

            function lav!(A::$matA{$elty}, b::$matb{$elty}, x::$matb{$elty}, ctrl::LPAffineCtrl{$elty})
                err = ccall(($(string("ElLAVX", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}, Ptr{Void}, LPAffineCtrl{$elty}),
                    A.obj, b.obj, x.obj, ctrl)
                err == 0 || throw(ElError(err))
                return x
            end
        end
    end
end

function lav{T<:Union{Float32,Float64}}(A::Matrix{T}, b::Matrix{T})
    x = Matrix(T)
    return lav!(A, b, x)
end
function lav{T<:Union{Float32,Float64}}(A::DistMatrix{T}, b::DistMatrix{T})
    x = DistMatrix(T, MC, MR, Grid(A))
    return lav!(A, b, x)
end
function lav{T<:Union{Float32,Float64}}(A::DistSparseMatrix{T}, b::DistMultiVec{T})
    x = DistMultiVec(T, comm(A))
    return lav!(A, b, x)
end

function lav{T<:Union{Float32,Float64}}(A::DistSparseMatrix{T}, b::DistMultiVec{T}, ctrl::LPAffineCtrl{T})
    x = DistMultiVec(T, comm(A))
    return lav!(A, b, x, ctrl)
end
