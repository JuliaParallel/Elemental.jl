# Linear Programming
# ==================
typealias ElLPApproach Cuint

const LP_ADMM = ElLPApproach(0)
const LP_MEHROTRA = ElLPApproach(1)

typealias ElKKTSystem Cuint

const FULL_KKT = ElKKTSystem(0)
const AUGMENTED_KKT = ElKKTSystem(1)
const NORMAL_KKT = ElKKTSystem(2)

immutable MehrotraCtrl{T<:ElFloatType}
    primalInit::ElBool
    dualInit::ElBool
    minTol::T
    targetTol::T
    maxIts::ElInt
    maxStepRatio::T
    system::ElKKTSystem
    mehrotra::ElBool
    forceSameStep::ElBool
    solveCtrl::RegSolveCtrl{T}
    resolveReg::ElBool
    outerEquil::ElBool
    basisSize::ElInt
    print::ElBool
    time::ElBool
    wSafeMaxNorm::T
    wMaxLimit::T
    ruizEquilTol::T
    ruizMaxIter::ElInt
    diagEquilTol::T
    checkResiduals::ElBool
end
function MehrotraCtrl{T<:ElFloatType}(::Type{T};
    primalInit::Bool = false,
    dualInit::Bool = false,
    minTol = eps(T)^0.3,
    targetTol = eps(T)^0.5,
    maxIts = 1000,
    maxStepRatio = 0.99,
    system = FULL_KKT,
    mehrotra = true,
    forceSameStep = true,
    solveCtrl = RegSolveCtrl(T),
    resolveReg = true,
    outerEquil::Bool = true,
    basisSize = 6,
    print = false,
    time = false,
    wSafeMaxNorm = eps(T)^(-0.15),
    wMaxLimit = eps(T)^(-0.4),
    ruizEquilTol = eps(T)^(-0.25),
    ruizMaxIter = 3,
    diagEquilTol = eps(T)^(-0.15),
    checkResiduals = false)

    MehrotraCtrl{T}(ElBool(primalInit),
                    ElBool(dualInit),
                    T(minTol),
                    T(targetTol),
                    ElInt(maxIts),
                    T(maxStepRatio),
                    ElKKTSystem(system),
                    ElBool(mehrotra),
                    ElBool(forceSameStep),
                    solveCtrl,
                    ElBool(resolveReg),
                    ElBool(outerEquil),
                    ElInt(basisSize),
                    ElBool(print),
                    ElBool(time),
                    T(wSafeMaxNorm),
                    T(wMaxLimit),
                    T(ruizEquilTol),
                    ElInt(ruizMaxIter),
                    T(diagEquilTol),
                    ElBool(checkResiduals))
end

immutable LPAffineCtrl{T<:ElFloatType}
    approach::Cuint
    mehrotraCtrl::MehrotraCtrl{T}
end

function LPAffineCtrl{T<:ElFloatType}(::Type{T};
    approach::Cuint = LP_MEHROTRA,
    mehrotraCtrl::MehrotraCtrl = MehrotraCtrl(T))

    LPAffineCtrl{T}(approach, mehrotraCtrl)
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
  @eval begin
    function LPAffine(
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
const SOCP_ADMM = Cuint(0)
const SOCP_IPF = Cuint(1)
const SOCP_IPF_SELFDUAL = Cuint(2)
const SOCP_MEHROTRA = Cuint(3)
const SOCP_MEHROTRA_SELFDUAL = Cuint(4)

immutable SOCPAffineCtrl{T<:ElFloatType}
    approach::Cuint
    mehrotraCtrl::MehrotraCtrl{T}
end
function SOCPAffineCtrl{T<:ElFloatType}(::Type{T};
                      approach::Cuint = SOCP_MEHROTRA,
                      mehrotraCtrl::MehrotraCtrl = MehrotraCtrl(T))
    SOCPAffineCtrl{T}(approach, mehrotraCtrl)
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d))
  @eval begin
    function SOCPAffine(
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
