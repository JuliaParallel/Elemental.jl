for dtype in ("", "Dist")
    for stype in ("", "Sparse")
        for (elty, ext) in ((:Float32, :s),
                            (:Float64, :d),
                            (:ComplexF32, :c),
                            (:ComplexF64, :z))
            mat = Symbol(dtype, stype, "Matrix")
            @eval begin
                function solve!(A::$mat{$elty}, B::$mat{$elty})
                    ElError(ccall(($(string("ElLinearSolve", dtype, stype, "_", ext)), libEl), Cuint,
                        (Ptr{Cvoid}, Ptr{Cvoid}),
                        A.obj, B.obj))
                    return B
                end
            end
        end
    end
end
