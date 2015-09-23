# SVD

for mattype in ("", "Dist")
    for (elty, ext) in ((:Float32, :s),
                        (:Float64, :d),
                        (:Complex64, :c),
                        (:Complex128, :z))
        mat = symbol(mattype, "Matrix")
        @eval begin
            function svdvals!(A::$mat{$elty})
                s = $mat(real($elty))
                err = ccall(($(string("ElSingularValues", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}),
                    A.obj, s.obj)
                err == 0 || throw(ElError(err))
                return s
            end

            function svd!(A::$mat{$elty})
                s = $mat(real($elty))
                V = $mat($elty)
                err = ccall(($(string("ElSVD", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}, Ptr{Void}),
                    A.obj, s.obj, V.obj)
                err == 0 || throw(ElError(err))
                return A, s, V
            end
        end
    end
end