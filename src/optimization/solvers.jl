const EL_LP_ADMM = Cuint(0)
const EL_LP_IPF = Cuint(1)
const EL_LP_IPF_SELFDUAL = Cuint(2)
const EL_LP_MEHROTRA = Cuint(3)
const EL_LP_MEHROTRA_SELFDUAL = Cuint(4)

immutable IPFLineSearchCtrl{T}
    gamma::T
    beta::T
    psi::T
    stepRatio::T
    progress::Cint
end
for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin
        function IPFLineSearchCtrl(::Type{$elty};
                                   gamma=1e-3,
                                   beta=2,
                                   psi=100,
                                   stepRatio=1.5,
                                   progress::Bool=false)
            return IPFLineSearchCtrl{$elty}(gamma, beta, psi, stepRatio, progress)
        end
    end
end

immutable LPAffineIPFCtrl{T}
    primalInit::Cint
    dualInit::Cint
    tol::T
    maxIts::Cint
    centering::T
    qsdCtrl::RegQSDCtrl{T}
    lineSearchCtrl::IPFLineSearchCtrl{T}
    equilibrate::Cint
    progress::Cint
    time::Cint
end
for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin
        function LPAffineIPFCtrl(::Type{$elty};
                                 primalInit::Bool=false,
                                 dualInit::Bool=false,
                                 tol=1e-8,
                                 maxIts=1000,
                                 centering=0.9,
                                 qsdCtrl::RegQSDCtrl=RegQSDCtrl($elty),
                                 lineSearchCtrl::IPFLineSearchCtrl=IPFLineSearchCtrl($elty),
                                 equilibrate::Bool=false,
                                 progress::Bool=false,
                                 time::Bool=false)
            return LPAffineIPFCtrl{$elty}(primalInit, dualInit, tol, maxIts,
                                          centering, qsdCtrl, lineSearchCtrl,
                                          equilibrate, progress, time)
        end
    end
end

immutable LPAffineMehrotraCtrl{T}
    primalInit::Cint
    dualInit::Cint
    tol::T
    maxIts::Cint
    maxStepRatio::T
    qsdCtrl::RegQSDCtrl{T}
    outerEquil::Cint
    innerEquil::Cint
    scaleTwoNorm::Cint
    basisSize::Cint
    progress::Cint
    time::Cint
end
for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin
        function LPAffineMehrotraCtrl(::Type{$elty};
                                      primalInit::Bool=false,
                                      dualInit::Bool=false,
                                      tol=1e-8,
                                      maxIts=100,
                                      maxStepRatio=0.99,
                                      qsdCtrl::RegQSDCtrl=RegQSDCtrl($elty),
                                      outerEquil::Bool=true,
                                      innerEquil::Bool=true,
                                      scaleTwoNorm::Bool=true,
                                      basisSize=15,
                                      progress::Bool=false,
                                      time::Bool=false)
            return LPAffineMehrotraCtrl{$elty}(primalInit, dualInit, tol, maxIts, maxStepRatio,
                                               qsdCtrl, outerEquil, innerEquil, scaleTwoNorm,
                                               basisSize, progress, time)
        end
    end
end

immutable LPAffineCtrl{T}
    approach::Cuint
    ipfCtrl::LPAffineIPFCtrl{T}
    mehrotraCtrl::LPAffineMehrotraCtrl{T}
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
    @eval begin
        function LPAffineCtrl(::Type{$elty};
                              approach::Cuint=EL_LP_MEHROTRA,
                              ipfCtrl::LPAffineIPFCtrl=LPAffineIPFCtrl($elty),
                              mehrotraCtrl::LPAffineMehrotraCtrl=LPAffineMehrotraCtrl($elty))
            return LPAffineCtrl{$elty}(approach, ipfCtrl, mehrotraCtrl)
        end
    end
end
