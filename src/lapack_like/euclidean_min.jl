for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d))
    for (matA, matB, sym) in ((:Matrix, :Matrix, "_"),
                              (:DistMatrix, :DistMatrix, "Dist_"),
                              (:SparseMatrix, :Matrix, "Sparse_"),
                              (:DistSparseMatrix, :DistMultiVec, "DistSparse_"))
        @eval begin
            function leastSquares!(A::$matA{$elty}, B::$matB{$elty}, X::$matB{$elty};
                orientation::Orientation = NORMAL)
                err = ccall(($(string("ElLeastSquares", sym, ext)), libEl), Cuint,
                    (Cuint, Ptr{Void}, Ptr{Void}, Ptr{Void}),
                    orientation, A.obj, B.obj, X.obj)
                err == 0 || throw(ElError(err))
                return X
            end
        end
    end
end

function leastSquares{T}(A::DistMatrix{T}, B::DistMatrix{T};
    orientation::Orientation = NORMAL)
    X = DistMatrix(T, MC, MR, Grid(A))
    return leastSquares!(A, B, X, orientation = orientation)
end
function leastSquares{T}(A::DistSparseMatrix{T}, B::DistMultiVec{T};
    orientation::Orientation = NORMAL)
    X = DistMultiVec(T, comm(A))
    return leastSquares!(A, B, X, orientation = orientation)
end
