for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin
        function leastSquares!(A::DistSparseMatrix{$elty},
                               B::DistMultiVec{$elty},
                               X::DistMultiVec{$elty};
                               orientation::Integer=EL_NORMAL)
            err = ccall(($(string("ElLeastSquaresDistSparse_", ext)), libEl), Cuint,
                        (Cint, Ptr{Void}, Ptr{Void}, Ptr{Void}),
                        orientation, A.obj, B.obj, X.obj)
            err == 0 || error("something is wrong here!")
            return X
        end

        function leastSquares(A::DistSparseMatrix{$elty},
                              B::DistMultiVec{$elty};
                              orientation::Integer=EL_NORMAL)
            X = similar(B, comm(A))
            return leastSquares!(A, B, X, orientation = orientation)
        end
    end
end
