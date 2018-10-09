for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d))
    for (matA, matB, sym) in ((:Matrix, :Matrix, "_"),
                              (:DistMatrix, :DistMatrix, "Dist_"),
                              (:SparseMatrix, :Matrix, "Sparse_"),
                              (:DistSparseMatrix, :DistMultiVec, "DistSparse_"))
        @eval begin
            function leastSquares!(A::$matA{$elty}, B::$matB{$elty}, X::$matB{$elty};
                orientation::Orientation = NORMAL)
                ElError(ccall(($(string("ElLeastSquares", sym, ext)), libEl), Cuint,
                    (Cuint, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                    orientation, A.obj, B.obj, X.obj))
                return X
            end
        end
    end
end

function leastSquares(A::DistMatrix{T}, B::DistMatrix{T};
    orientation::Orientation = NORMAL) where {T}
    X = DistMatrix(T, MC, MR, A.g)
    return leastSquares!(A, B, X, orientation = orientation)
end
function leastSquares(A::DistSparseMatrix{T}, B::DistMultiVec{T};
    orientation::Orientation = NORMAL) where {T}
    X = DistMultiVec(T, comm(A))
    return leastSquares!(A, B, X, orientation = orientation)
end
