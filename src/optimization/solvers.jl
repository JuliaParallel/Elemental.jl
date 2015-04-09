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
                                   progress=false)
            obj = IPFLineSearchCtrl{$elty}(gamma, beta, psi, stepRatio, progress)
            err = ccall(($(string("ElIPFLineSearchCtrlDefault_", ext)), libEl), Cuint,
                (Ref{IPFLineSearchCtrl{$elty}},), Ref(obj))
            err == 0 || error("something is wrong here!")
            return obj
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
            obj = LPAffineIPFCtrl{$elty}(primalInit, dualInit, tol, maxIts, centering,
                                         qsdCtrl, lineSearchCtrl, equilibrate, progress, time)
            err = ccall(($(string("ElLPAffineIPFCtrlDefault_", ext)), libEl), Cuint,
                (Ptr{LPAffineIPFCtrl{$elty}},),
                 &obj)
            err == 0 || error("something is wrong here!")
            return obj
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
            obj = LPAffineMehrotraCtrl{$elty}(primalInit, dualInit, tol, maxIts, maxStepRatio,
                                              qsdCtrl, outerEquil, innerEquil, scaleTwoNorm,
                                              basisSize, progress, time)
            err = ccall(($(string("ElLPAffineMehrotraCtrlDefault_", ext)), libEl), Cuint,
                (Ptr{LPAffineMehrotraCtrl{$elty}},),
                &obj)
            err == 0 || error("something is wrong here!")
            return obj
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
                              ipfCtrl::LPAffineCtrl=LPAffineCtrl($elty),
                              mehrotraCtrl::LPAffineMehrotraCtrl=LPAffineMehrotraCtrl($elty))
            obj = LPAffineCtrl{$elty}(approach, ipfCtrl, mehrotraCtrl)
            err = ccall(($(string("ElLPAffineCtrlDefault_", ext)), libEl), Cuint,
                (Ptr{LPAffineCtrl{$elty}},),
                &obj)
            err == 0 || error("something is wrong here!")
            return obj
        end
    end
end
