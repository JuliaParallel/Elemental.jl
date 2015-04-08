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
        function IPFLineSearchCtrl(::Type{$elty})
            obj = IPFLineSearchCtrl{$elty}(0, 0, 0, 0, 0)
            err = ccall(($(string("ElIPFLineSearchCtrlDefault_", ext)), libEl), Cuint,
                (Ptr{IPFLineSearchCtrl{$elty}},),
                 &obj)
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
        function LPAffineIPFCtrl(::Type{$elty})
            obj = LPAffineIPFCtrl{$elty}(0, 0, 0, 0, 0, RegQSDCtrl($elty), IPFLineSearchCtrl($elty), 0, 0, 0)
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
        function LPAffineMehrotraCtrl(::Type{$elty})
            obj = LPAffineMehrotraCtrl{$elty}(0, 0, 0, 0, 0, RegQSDCtrl($elty), 0, 0, 0, 0, 0, 0)
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
        function LPAffineCtrl(::Type{$elty})
            obj = LPAffineCtrl{$elty}(0, LPAffineIPFCtrl($elty), LPAffineMehrotraCtrl($elty))
            err = ccall(($(string("ElLPAffineCtrlDefault_", ext)), libEl), Cuint,
                (Ptr{LPAffineCtrl{$elty}},),
                &obj)
            err == 0 || error("something is wrong here!")
            return obj
        end
    end
end
