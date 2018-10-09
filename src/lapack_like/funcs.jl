for dtype in ("", "Dist")
    for (elty, ext) in ((:Float32, :s),
                        (:Float64, :d),
                        (:ComplexF32, :c),
                        (:ComplexF64, :z))
        mat = Symbol(dtype, "Matrix")
        @eval begin
            function inverse!(A::$mat{$elty})
                ElError(ccall(($(string("ElInverse", dtype, "_", ext)), libEl), Cuint,
                    (Ptr{Cvoid},),
                    A.obj,))
                return A
            end
        end
    end
end
