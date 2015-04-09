const EL_REG_REFINE_FGMRES = Cuint(0)
const EL_REG_REFINE_LGMRES = Cuint(1)
const EL_REG_REFINE_IR = Cuint(2)
const EL_REG_REFINE_IR_MOD = Cuint(3)

immutable RegQSDCtrl{T}
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
                            regPrimal=eps($elty)^$elty(0.5),
                            regDual=eps($elty)^$elty(0.5),
                            alg=EL_REG_REFINE_FGMRES,
                            relTol=eps($elty)^$elty(0.5),
                            relTolRefine=eps($elty)^$elty(0.5),
                            maxRefineIts=50,
                            restart=10,
                            progress=false)
            obj = RegQSDCtrl{$elty}(regPrimal, regDual, alg,
                                    relTol, relTolRefine, maxRefineIts,
                                    restart, progress)
            err = ccall(($(string("ElRegQSDCtrlDefault_", ext)), libEl), Cuint,
                        (Ref{RegQSDCtrl{$elty}},), Ref(obj))
            err == 0 || error("something is wrong here!")
            return obj
        end
    end
end
