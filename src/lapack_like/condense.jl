for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:ComplexF32, :c),
                    (:ComplexF64, :z))
    for mattype in ("", "Dist")
        mat = Symbol(mattype, "Matrix")
        @eval begin

            # Hessenberg
            function _hessenberg!(uplo::UpperOrLower, A::$mat{$elty}, t::$mat{$elty})
                ElError(ccall(($(string("ElHessenberg", mattype, "_", ext)), libEl), Cuint,
                    (UpperOrLower, Ptr{Cvoid}, Ptr{Cvoid}),
                    uplo, A.obj, t.obj))
                return A, t
            end
            _hessenberg!(A::$mat{$elty}) = _hessenberg!(UPPER, A, $mat($elty))
        end
    end
end

struct ElHessenberg{T,S<:ElementalMatrix} <: LinearAlgebra.Factorization{T}
    factors::S
    τ::S
    ElHessenberg{T,S}(factors::ElementalMatrix{T}, τ::ElementalMatrix{T}) where {T,S<:ElementalMatrix} = new{T,S}(factors, τ)
end

ElHessenberg(factors::ElementalMatrix{T}, τ::ElementalMatrix{T}) where {T} = ElHessenberg{T,typeof(factors)}(factors, τ)

LinearAlgebra.hessenberg!(A::ElementalMatrix) = ElHessenberg(_hessenberg!(A)...)
