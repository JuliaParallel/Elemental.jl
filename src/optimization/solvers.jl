# Linear Programming
# ==================
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
    progress::ElBool
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
    primalInit::ElBool
    dualInit::ElBool
    minTol::T
    targetTol::T
    maxIts::ElInt
    centering::T
    qsdCtrl::RegQSDCtrl{T}
    lineSearchCtrl::IPFLineSearchCtrl{T}
    equilibrate::ElBool
    progress::ElBool
    time::ElBool
end
function LPAffineIPFCtrl{T<:ElFloatType}(::Type{T};
                         primalInit::Bool=false,
                         dualInit::Bool=false,
                         minTol=eps(T)^0.3,
                         targetTol=eps(T)^0.5,
                         maxIts=1000,
                         centering=0.9,
                         qsdCtrl::RegQSDCtrl=RegQSDCtrl(T),
                         lineSearchCtrl::IPFLineSearchCtrl=IPFLineSearchCtrl(T),
                         equilibrate::Bool=false,
                         progress::Bool=false,
                         time::Bool=false)
    LPAffineIPFCtrl{T}(primalInit, dualInit, minTol, targetTol, maxIts,
                       centering, qsdCtrl, lineSearchCtrl,
                       equilibrate, progress, time)
end

immutable LPAffineMehrotraCtrl{T<:ElFloatType}
    primalInit::ElBool
    dualInit::ElBool
    minTol::T
    targetTol::T
    maxIts::ElInt
    maxStepRatio::T
    qsdCtrl::RegQSDCtrl{T}
    outerEquil::ElBool
    innerEquil::ElBool
    scaleTwoNorm::ElBool
    basisSize::ElInt
    progress::ElBool
    time::ElBool
end
function LPAffineMehrotraCtrl{T<:ElFloatType}(::Type{T};
                              primalInit::Bool=false,
                              dualInit::Bool=false,
                              minTol=eps(T)^0.3,
                              targetTol=eps(T)^0.5,
                              maxIts=100,
                              maxStepRatio=0.99,
                              qsdCtrl::RegQSDCtrl=RegQSDCtrl(T),
                              outerEquil::Bool=true,
                              innerEquil::Bool=true,
                              scaleTwoNorm::Bool=true,
                              basisSize=15,
                              progress::Bool=false,
                              time::Bool=false)
    LPAffineMehrotraCtrl{T}(primalInit, dualInit, minTol, targetTol, maxIts,
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

# Second-Order Cone Programming
# =============================
const EL_SOCP_ADMM = Cuint(0)
const EL_SOCP_IPF = Cuint(1)
const EL_SOCP_IPF_SELFDUAL = Cuint(2)
const EL_SOCP_MEHROTRA = Cuint(3)
const EL_SOCP_MEHROTRA_SELFDUAL = Cuint(4)

immutable SOCPAffineMehrotraCtrl{T<:ElFloatType}
    primalInit::ElBool
    dualInit::ElBool
    minTol::T
    targetTol::T
    maxIts::ElInt
    maxStepRatio::T
    qsdCtrl::RegQSDCtrl{T}
    outerEquil::ElBool
    innerEquil::ElBool
    scaleTwoNorm::ElBool
    basisSize::ElInt
    progress::ElBool
    time::ElBool
end
function SOCPAffineMehrotraCtrl{T<:ElFloatType}(::Type{T};
                              primalInit::Bool=false,
                              dualInit::Bool=false,
                              minTol=eps(T)^0.3,
                              targetTol=eps(T)^0.5,
                              maxIts=100,
                              maxStepRatio=0.99,
                              qsdCtrl::RegQSDCtrl=RegQSDCtrl(T),
                              outerEquil::Bool=true,
                              innerEquil::Bool=true,
                              scaleTwoNorm::Bool=true,
                              basisSize=15,
                              progress::Bool=false,
                              time::Bool=false)
    SOCPAffineMehrotraCtrl{T}(primalInit, dualInit, minTol, targetTol, maxIts,
                            maxStepRatio, qsdCtrl, outerEquil,
                            innerEquil, scaleTwoNorm,
                            basisSize, progress, time)
end

immutable SOCPAffineCtrl{T<:ElFloatType}
    approach::Cuint
    mehrotraCtrl::SOCPAffineMehrotraCtrl{T}
end
function SOCPAffineCtrl{T<:ElFloatType}(::Type{T};
                      approach::Cuint=EL_SOCP_MEHROTRA,
                      mehrotraCtrl::SOCPAffineMehrotraCtrl=SOCPAffineMehrotraCtrl(T))
    SOCPAffineCtrl{T}(approach, mehrotraCtrl)
end

