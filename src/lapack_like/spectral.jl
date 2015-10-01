# SVD
immutable SVDCtrl{T<:ElFloatType}
    seqQR::ElBool
    valChanRatio::Cdouble
    fullChanRatio::Cdouble
    thresholded::ElBool
    relative::ElBool
    tol::T
end

function SVDCtrl{T<:ElFloatType}(::Type{T};
    seqQR = false,
    valChanRatio = 1.2,
    fullChanRatio = 1.5,
    thresholded = false,
    relative = true,
    tol = 0.0)

    SVDCtrl(ElBool(seqQR),
        Cdouble(valChanRatio),
        Cdouble(fullChanRatio),
        ElBool(thresholded),
        ElBool(relative),
        T(tol))
end

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

            function svdvals!(A::$mat{$elty}, ctrl::SVDCtrl{real($elty)})
                s = $mat(real($elty))
                err = ccall(($(string("ElSingularValuesX", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}, SVDCtrl{real($elty)}),
                    A.obj, s.obj, ctrl)
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

            function svd!(A::$mat{$elty}, ctrl::SVDCtrl{real($elty)})
                s = $mat(real($elty))
                V = $mat($elty)
                err = ccall(($(string("ElSVDX", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}, Ptr{Void}, SVDCtrl{real($elty)}),
                    A.obj, s.obj, V.obj, ctrl)
                err == 0 || throw(ElError(err))
                return A, s, V
            end
        end
    end
end
