for dtype in ("", "Dist")
    for (elty, ext) in ((:Float32, :s),
                        (:Float64, :d),
                        (:Complex64, :c),
                        (:Complex128, :z))
        mat = Symbol(dtype, "Matrix")
        @eval begin
            function inverse!(A::$mat{$elty})
                err = ccall(($(string("ElInverse", dtype, "_", ext)), libEl), Cuint,
                    (Ptr{Void},),
                    A.obj,)
                err == 0 || throw(ElError(err))
                return A
            end
        end
    end
end
