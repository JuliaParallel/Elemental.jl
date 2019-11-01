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

for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d))
    for (matA, matB, sym) in ((:(Elemental.Matrix), :(Elemental.Matrix), "_"),
                              (:DistMatrix, :DistMatrix, "Dist_"),
                              (:(Elemental.SparseMatrix), :(Elemental.Matrix), "Sparse_"),
                              (:DistSparseMatrix, :DistMultiVec, "DistSparse_"))
        @eval begin
            function bpdn!(A::$matA{$elty}, B::$matB{$elty}, lambda::$elty, X::$matB{$elty})
                ElError(ccall(($(string("ElBPDNX", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, $elty, Ptr{Cvoid}, Cuint),
                    A.obj, B.obj, lambda, X.obj, 0))
                return X
            end
        end
    end
end

function bpdn(A::DistMatrix{T}, B::DistMatrix{T}, lambda::T) where {T}
    X = DistMatrix(T, MC, MR, A.g)
    return bpdn!(A, B, lambda, X)
end
function bpdn(A::DistSparseMatrix{T}, B::DistMultiVec{T}, lambda) where {T}
    X = DistMultiVec(T, comm(A))
    return bpdn!(A, B, lambda, X)
end

@enum RidgeAlg RIDGE_CHOLESKY RIDGE_QR RIDGE_SVD

for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d))
    for (matA, matB, sym) in ((:(Elemental.Matrix), :(Elemental.Matrix), "_"),
                              (:DistMatrix, :DistMatrix, "Dist_"),
                              (:(Elemental.SparseMatrix), :(Elemental.Matrix), "Sparse_"),
                              (:DistSparseMatrix, :DistMultiVec, "DistSparse_"))
        @eval begin
            function ridge!(A::$matA{$elty}, B::$matB{$elty}, gamma::$elty, X::$matB{$elty};
                orientation::Orientation = NORMAL, alg::RidgeAlg = RIDGE_CHOLESKY)
                ElError(ccall(($(string("ElRidge", sym, ext)), libEl), Cuint,
                    (Cuint, Ptr{Cvoid}, Ptr{Cvoid}, $elty, Ptr{Cvoid}, Cuint),
                    orientation, A.obj, B.obj, gamma, X.obj, alg))
                return X
            end
        end
    end
end

function ridge(A::DistMatrix{T}, B::DistMatrix{T}, gamma::T; ka...) where {T}
    X = DistMatrix(T, MC, MR, A.g)
    return ridge!(A, B, gamma, X; ka...)
end
function ridge(A::DistSparseMatrix{T}, B::DistMultiVec{T}, gamma::T; ka...) where {T}
    X = DistMultiVec(T, comm(A))
    return ridge!(A, B, gamma, X; ka...)
end