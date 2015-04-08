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
        function RegQSDCtrl(::Type{$elty})
            obj = RegQSDCtrl{$elty}(0, 0, 0, 0, 0, 0, 0, 0)
            err = ccall(($(string("ElRegQSDCtrlDefault_", ext)), libEl), Cuint,
                        (Ptr{RegQSDCtrl{$elty}},), &obj)
            err == 0 || error("something is wrong here!")
            return obj
        end
    end
end
