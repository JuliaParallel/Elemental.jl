const EL_REG_REFINE_FGMRES = Cuint(0)
const EL_REG_REFINE_LGMRES = Cuint(1)
const EL_REG_REFINE_IR = Cuint(2)
const EL_REG_REFINE_IR_MOD = Cuint(3)

immutable RegQSDCtrl{T<:ElFloatType}
    regPrimal::T
    regDual::T
    alg::Cuint
    relTol::T
    relTolRefine::T
    maxRefineIts::ElInt
    restart::ElInt
    progress::Uint8
end
function RegQSDCtrl{T<:ElFloatType}(::Type{T};
                    regPrimal=eps(T)^convert(T, 0.5),
                    regDual=eps(T)^convert(T, 0.5),
                    alg=EL_REG_REFINE_FGMRES,
                    relTol=eps(T)^convert(T, 0.5),
                    relTolRefine=eps(T)^convert(T, 0.5),
                    maxRefineIts=50,
                    restart=10,
                    progress::Bool=false)
    RegQSDCtrl{T}(regPrimal, regDual, alg,
                  relTol, relTolRefine,
                  maxRefineIts, restart,
                  progress)
end
