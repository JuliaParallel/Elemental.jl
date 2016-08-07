for dtype in ("", "Dist")
    for stype in ("", "Sparse")
        for (elty, ext) in ((:Float32, :s),
                            (:Float64, :d),
                            (:Complex64, :c),
                            (:Complex128, :z))
            mat = Symbol(dtype, stype, "Matrix")
            @eval begin
                function solve!(A::$mat{$elty}, B::$mat{$elty})
                    err = ccall(($(string("ElLinearSolve", dtype, stype, "_", ext)), libEl), Cuint,
                        (Ptr{Void}, Ptr{Void}),
                        A.obj, B.obj)
                    err == 0 || throw(ElError(err))
                    return B
                end
            end
        end
    end
end
