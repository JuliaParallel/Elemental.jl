for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))

    # Distributed sparse gemv
    for (trans, elenum) in (("", :NORMAL), ("t", :TRANSPOSE), ("c", :ADJOINT))

        f = Symbol("A", trans, "_mul_B!")

        @eval begin
            function ($f)(α::$elty, A::DistSparseMatrix{$elty}, x::DistMultiVec{$elty}, β::$elty, y::DistMultiVec{$elty})
                err = ccall(($(string("ElMultiplyDist_", ext)), libEl), Cuint,
                    (Cint, $elty, Ptr{Void}, Ptr{Void}, $elty, Ptr{Void}),
                    $elenum, α, A.obj, x.obj, β, y.obj)
                err == 0 || throw(ElError(err))
                return y
            end
        end
    end
end