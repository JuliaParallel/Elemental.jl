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

function RegQSDCtrl(::Type{Float64};
                    regPrimal=eps(Float64)^0.5,
                    regDual=eps(Float64)^0.5,
                    alg=EL_REG_REFINE_FGMRES,
                    relTol=eps(Float64)^0.5,
                    relTolRefine=eps(Float64)^0.5,
                    maxRefineIts=50,
                    restart=10,
                    progress::Bool=false)
    obj = Ref(RegQSDCtrl{Float64}(regPrimal, regDual, alg,
                                  relTol, relTolRefine, maxRefineIts,
                                  restart, progress))
    err = ccall((:ElRegQSDCtrlDefault_d, libEl), Cuint,
                (Ref{RegQSDCtrl{Float64}},), obj)
    err == 0 || error("something is wrong here!")
    return obj[]
end

#= TODO: segfault / possible typeinf eval bug
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
                            progress=false)
            obj = Ref(RegQSDCtrl{$elty}(regPrimal, regDual, alg,
                                        relTol, relTolRefine, maxRefineIts,
                                        restart, progress))
            err = ccall(($(string("ElRegQSDCtrlDefault_", ext)), libEl), Cuint,
                        (Ref{RegQSDCtrl{$elty}},), obj)
            err == 0 || error("something is wrong here!")
            return obj[]
        end
    end
end
=#
