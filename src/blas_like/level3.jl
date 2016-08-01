for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))

    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"))

        for (transA, elenumA) in (("", :NORMAL), ("t", :TRANSPOSE), ("c", :ADJOINT))
            for (transB, elenumB) in (("", :NORMAL), ("t", :TRANSPOSE), ("c", :ADJOINT))
                f = Symbol("A", transA, "_mul_B", transB, "!")

                @eval begin
                    function ($f)(α::$elty, A::$mat{$elty}, B::$mat{$elty}, β::$elty, C::$mat{$elty})
                        err = ccall(($(string("ElGemm", sym, ext)), libEl), Cuint,
                            (Cint, Cint, $elty, Ptr{Void}, Ptr{Void}, $elty, Ptr{Void}),
                            $elenumA, $elenumB, α, A.obj, B.obj, β, C.obj)
                        err == 0 || throw(ElError(err))
                        return C
                    end
                end
            end
        end
    end
end
