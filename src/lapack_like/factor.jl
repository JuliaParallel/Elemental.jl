const RegSolveAlg = Cuint

const REG_SOLVE_FGMRES = RegSolveAlg(0)
const REG_SOLVE_LGMRES = RegSolveAlg(1)

struct RegSolveCtrl{T<:ElFloatType}
    alg::RegSolveAlg
    relTol::T
    relTolRefine::T
    maxIts::ElInt
    maxRefineIts::ElInt
    restart::ElInt
    progress::ElBool
    time::ElBool
end

function RegSolveCtrl(::Type{T};
                    alg = REG_SOLVE_FGMRES,
                    relTol = eps(T)^0.5,
                    relTolRefine = eps(T)^0.8,
                    maxIts = 4,
                    maxRefineIts = 2,
                    restart = 4,
                    progress = false,
                    time = false) where {T<:ElFloatType}

    RegSolveCtrl{T}(RegSolveAlg(alg),
        T(relTol),
        T(relTolRefine),
        ElInt(maxIts),
        ElInt(maxRefineIts),
        ElInt(restart),
        ElBool(progress),
        ElBool(time))
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:ComplexF32, :c),
                    (:ComplexF64, :z))
    for mattype in ("", "Dist")
        mat = Symbol(mattype, "Matrix")
        @eval begin

            function _cholesky(uplo::UpperOrLower, A::$mat{$elty})
                ElError(ccall(($(string("ElCholesky", mattype, "_", ext)), libEl), Cuint,
                    (UpperOrLower, Ptr{Cvoid}),
                    uplo, A.obj))
                return A
            end
        end
    end
end
