for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin

        function lav(A::DistSparseMatrix{$elty}, b::DistMultiVec{$elty})
            x = DistMultiVec($elty, comm(A))
            err = ccall(($(string("ElLAVDistSparse_", ext)), libEl), Cuint, 
                (Ptr{Void}, Ptr{Void}, Ptr{Void}),
                A.obj, b.obj, x.obj)
            err == 0 || error("something is wrong here!")
            return x
        end

        function lav(A::DistSparseMatrix{$elty}, b::DistMultiVec{$elty}, ctrl::LPAffineCtrl{$elty})
            x = DistMultiVec($elty, comm(A))
            err = ccall(($(string("ElLAVXDistSparse_", ext)), libEl), Cuint,
                (Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{LPAffineCtrl{$elty}}),
                A.obj, b.obj, x.obj, &ctrl)
            err == 0 || error("something is wrong here!")
            return x
        end
    end
end