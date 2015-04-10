const EL_LP_ADMM = Cuint(0)
const EL_LP_IPF = Cuint(1)
const EL_LP_IPF_SELFDUAL = Cuint(2)
const EL_LP_MEHROTRA = Cuint(3)
const EL_LP_MEHROTRA_SELFDUAL = Cuint(4)

immutable IPFLineSearchCtrl{T<:ElFloatType}
    gamma::T
    beta::T
    psi::T
    stepRatio::T
    progress::Uint8
end
function IPFLineSearchCtrl{T<:ElFloatType}(::Type{T};
                           gamma=1e-3,
                           beta=2,
                           psi=100,
                           stepRatio=1.5,
                           progress::Bool=false)
    IPFLineSearchCtrl{T}(gamma, beta, psi, stepRatio, progress)
end

immutable LPAffineIPFCtrl{T<:ElFloatType}
    primalInit::Uint8
    dualInit::Uint8
    tol::T
    maxIts::ElInt
    centering::T
    qsdCtrl::RegQSDCtrl{T}
    lineSearchCtrl::IPFLineSearchCtrl{T}
    equilibrate::Uint8
    progress::Uint8
    time::Uint8
end
function LPAffineIPFCtrl{T<:ElFloatType}(::Type{T};
                         primalInit::Bool=false,
                         dualInit::Bool=false,
                         tol=1e-8,
                         maxIts=1000,
                         centering=0.9,
                         qsdCtrl::RegQSDCtrl=RegQSDCtrl(T),
                         lineSearchCtrl::IPFLineSearchCtrl=IPFLineSearchCtrl(T),
                         equilibrate::Bool=false,
                         progress::Bool=false,
                         time::Bool=false)
    LPAffineIPFCtrl{T}(primalInit, dualInit, tol, maxIts,
                       centering, qsdCtrl, lineSearchCtrl,
                       equilibrate, progress, time)
end

immutable LPAffineMehrotraCtrl{T<:ElFloatType}
    primalInit::Uint8
    dualInit::Uint8
    tol::T
    maxIts::ElInt
    maxStepRatio::T
    qsdCtrl::RegQSDCtrl{T}
    outerEquil::Uint8
    innerEquil::Uint8
    scaleTwoNorm::Uint8
    basisSize::ElInt
    progress::Uint8
    time::Uint8
end
function LPAffineMehrotraCtrl{T<:ElFloatType}(::Type{T};
                              primalInit::Bool=false,
                              dualInit::Bool=false,
                              tol=1e-8,
                              maxIts=100,
                              maxStepRatio=0.99,
                              qsdCtrl::RegQSDCtrl=RegQSDCtrl(T),
                              outerEquil::Bool=true,
                              innerEquil::Bool=true,
                              scaleTwoNorm::Bool=true,
                              basisSize=15,
                              progress::Bool=false,
                              time::Bool=false)
    LPAffineMehrotraCtrl{T}(primalInit, dualInit, tol, maxIts,
                            maxStepRatio, qsdCtrl, outerEquil,
                            innerEquil, scaleTwoNorm,
                            basisSize, progress, time)
end

immutable LPAffineCtrl{T<:ElFloatType}
    approach::Cuint
    ipfCtrl::LPAffineIPFCtrl{T}
    mehrotraCtrl::LPAffineMehrotraCtrl{T}
end
function LPAffineCtrl{T<:ElFloatType}(::Type{T};
                      approach::Cuint=EL_LP_MEHROTRA,
                      ipfCtrl::LPAffineIPFCtrl=LPAffineIPFCtrl(T),
                      mehrotraCtrl::LPAffineMehrotraCtrl=LPAffineMehrotraCtrl(T))
    LPAffineCtrl{T}(approach, ipfCtrl, mehrotraCtrl)
end
