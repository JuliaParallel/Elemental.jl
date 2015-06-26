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
    IPFLineSearchCtrl{T}(gamma, beta, psi, stepRatio, ElBool(progress))
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
                         minTol=eps(T)^convert(T,0.3),
                         targetTol=eps(T)^convert(T,0.5),
                         maxIts=1000,
                         centering=0.9,
                         qsdCtrl::RegQSDCtrl=RegQSDCtrl(T),
                         lineSearchCtrl::IPFLineSearchCtrl=IPFLineSearchCtrl(T),
                         equilibrate::Bool=false,
                         progress::Bool=false,
                         time::Bool=false)
    LPAffineIPFCtrl{T}(ElBool(primalInit), ElBool(dualInit), minTol, targetTol,
                       maxIts, centering, qsdCtrl, lineSearchCtrl,
                       ElBool(equilibrate), ElBool(progress), ElBool(time))
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
                              minTol=eps(T)^convert(T,0.3),
                              targetTol=eps(T)^convert(T,0.5),
                              maxIts=100,
                              maxStepRatio=0.99,
                              qsdCtrl::RegQSDCtrl=RegQSDCtrl(T),
                              outerEquil::Bool=true,
                              innerEquil::Bool=true,
                              scaleTwoNorm::Bool=true,
                              basisSize=15,
                              progress::Bool=false,
                              time::Bool=false)
    LPAffineMehrotraCtrl{T}(ElBool(primalInit), ElBool(dualInit), 
                            minTol, targetTol, maxIts, maxStepRatio, qsdCtrl, 
                            ElBool(outerEquil), ElBool(innerEquil), 
                            ElBool(scaleTwoNorm),
                            basisSize, ElBool(progress), ElBool(time))
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

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
  @eval begin
    function LPAffine{$elty}(
      A::DistSparseMatrix{$elty},
      G::DistSparseMatrix{$elty},
      b::DistMultiVec{$elty},
      c::DistMultiVec{$elty},
      h::DistMultiVec{$elty},
      x::DistMultiVec{$elty},
      y::DistMultiVec{$elty},
      z::DistMultiVec{$elty},
      s::DistMultiVec{$elty},
      ctrl::LPAffineCtrl=SOCPAffineCtrl($elty))
      err = ccall(($(string("ElLPAffine_", ext)), libEl), Cuint,
        (Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void},
         Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void},
         LPAffineCtrl{$elty}),
        A.obj, G.obj, b.obj, c.obj, h.obj,
        x.obj, y.obj, z.obj, s.obj, ctrl)
      err == 0 || throw(ElError(err))
      return nothing
    end
  end
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
                              minTol=eps(T)^convert(T,0.3),
                              targetTol=eps(T)^convert(T,0.5),
                              maxIts=100,
                              maxStepRatio=0.99,
                              qsdCtrl::RegQSDCtrl=RegQSDCtrl(T),
                              outerEquil::Bool=true,
                              innerEquil::Bool=true,
                              scaleTwoNorm::Bool=true,
                              basisSize=15,
                              progress::Bool=false,
                              time::Bool=false)
    SOCPAffineMehrotraCtrl{T}(ElBool(primalInit), ElBool(dualInit), 
                            minTol, targetTol, maxIts,
                            maxStepRatio, qsdCtrl, ElBool(outerEquil),
                            ElBool(innerEquil), ElBool(scaleTwoNorm),
                            basisSize, ElBool(progress), ElBool(time))
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

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
  @eval begin
    function SOCPAffine{$elty}(
      A::DistSparseMatrix{$elty},
      G::DistSparseMatrix{$elty},
      b::DistMultiVec{$elty},
      c::DistMultiVec{$elty},
      h::DistMultiVec{$elty},
      orders::DistMultiVec{ElInt},
      firstInds::DistMultiVec{ElInt},
      labels::DistMultiVec{ElInt},
      x::DistMultiVec{$elty},
      y::DistMultiVec{$elty},
      z::DistMultiVec{$elty},
      s::DistMultiVec{$elty},
      ctrl::SOCPAffineCtrl=SOCPAffineCtrl($elty))
      err = ccall(($(string("ElSOCPAffine_", ext)), libEl), Cuint,
        (Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void},
         Ptr{Void},Ptr{Void},Ptr{Void},
         Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void},
         SOCPAffineCtrl{$elty}),
        A.obj, G.obj, b.obj, c.obj, h.obj,
        orders.obj, firstInds.obj, labels.obj,
        x.obj, y.obj, z.obj, s.obj, ctrl)
      err == 0 || throw(ElError(err))
      return nothing
    end
  end
end
