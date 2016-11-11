for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    for mattype in ("", "Dist")
        mat = Symbol(mattype, "Matrix")
        @eval begin

            # Hessenberg
            function hessenberg!(uplo::UpperOrLower, A::$mat{$elty}, t::$mat{$elty})
                err = ccall(($(string("ElHessenberg", mattype, "_", ext)), libEl), Cuint,
                    (UpperOrLower, Ptr{Void}, Ptr{Void}),
                    uplo, A.obj, t.obj)
                err == 0 || throw(ElError(err))
                return A, t
            end
            hessenberg!(A::$mat{$elty}) = hessenberg!(UPPER, A, $mat($elty))
        end
    end
end

immutable ElHessenberg{T,S<:ElementalMatrix} <: Factorization{T}
    factors::S
    τ::S
    ElHessenberg(factors::ElementalMatrix{T}, τ::ElementalMatrix{T}) = new(factors, τ)
end

ElHessenberg{T}(factors::ElementalMatrix{T}, τ::ElementalMatrix{T}) = ElHessenberg{T,typeof(factors)}(factors, τ)

Base.LinAlg.hessfact!(A::ElementalMatrix) = ElHessenberg(hessenberg!(A)...)
