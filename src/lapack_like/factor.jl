const EL_REG_REFINE_FGMRES = Cuint(0)
const EL_REG_REFINE_LGMRES = Cuint(1)
const EL_REG_REFINE_IR = Cuint(2)
const EL_REG_REFINE_IR_MOD = Cuint(3)

typealias ElFloatType Union(Float64,Float32)

immutable RegQSDCtrl{T<:ElFloatType}
    regPrimal::T
    regDual::T
    alg::Cuint
    relTol::T
    relTolRefine::T
    maxRefineIts::Cint
    restart::Cint
    progress::Cint
end
for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin
        function RegQSDCtrl(::Type{$elty};
                            regPrimal=eps($elty)^convert($elty, 0.5),
                            regDual=eps($elty)^convert($elty, 0.5),
                            alg=EL_REG_REFINE_FGMRES,
                            relTol=eps($elty)^convert($elty, 0.5),
                            relTolRefine=eps($elty)^convert($elty, 0.5),
                            maxRefineIts=50,
                            restart=10,
                            progress::Bool=false)
            return RegQSDCtrl{$elty}(regPrimal, regDual, alg,
                                     relTol, relTolRefine, maxRefineIts,
                                     restart, progress)
        end
    end
end
