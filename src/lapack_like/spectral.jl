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

immutable SpectralBox{T}
    center::Complex{T}
    realWidth::T
    imagWidth::T
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    for mattype in ("", "Dist")
        mat = symbol(mattype, "Matrix")
        @eval begin

            function eigvalsTridiag(d::$mat{real($elty)}, dSub::$mat{$elty}, sort::SortType = ASCENDING)
                w = $mat(real($elty))
                err = ccall(($(string("ElHermitianTridiagEig", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}, Ptr{Void}, SortType),
                    d.obj, dSub.obj, w.obj, sort)
                err == 0 || throw(ElError(err))
                return w
            end

            function eigTridiag(d::$mat{real($elty)}, dSub::$mat{$elty}, sort::SortType = ASCENDING)
                w = $mat(real($elty))
                Z = $mat($elty)
                err = ccall(($(string("ElHermitianTridiagEigPair", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}, SortType),
                    d.obj, dSub.obj, w.obj, Z.obj, sort)
                err == 0 || throw(ElError(err))
                return w, Z
            end

            function eigvalsHermitian(uplo::UpperOrLower, A::$mat{$elty}, sort::SortType = ASCENDING)
                w = $mat(real($elty))
                err = ccall(($(string("ElHermitianEig", mattype, "_", ext)), libEl), Cuint,
                    (UpperOrLower, Ptr{Void}, Ptr{Void}, SortType),
                    uplo, A.obj, w.obj, sort)
                err == 0 || throw(ElError(err))
                return w
            end

            function eigHermitian(uplo::UpperOrLower, A::$mat{$elty}, sort::SortType = ASCENDING)
                w = $mat(real($elty))
                Z = $mat($elty)
                err = ccall(($(string("ElHermitianEigPair", mattype, "_", ext)), libEl), Cuint,
                    (UpperOrLower, Ptr{Void}, Ptr{Void}, Ptr{Void}, SortType),
                    uplo, A.obj, w.obj, Z.obj, sort)
                err == 0 || throw(ElError(err))
                return w, Z
            end

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

            function spectralProtrait(A::$mat{$elty}, realSize::ElInt, imagSize::ElInt)
                invNormMap = $mat(real($elty))
                box = Ref{SpectralBox{real($elty)}}()
                err = ccall(($(string("ElSpectralPortrait", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}, ElInt, ElInt, Ref{SpectralBox{real($elty)}}),
                    A.obj, invNormMap.obj, realSize, imagSize, box)
                err == 0 || throw(ElError(err))
                return invNormMap, box[]
            end
        end
    end
end
