typealias RegSolveAlg Cuint

const REG_SOLVE_FGMRES = RegSolveAlg(0)
const REG_SOLVE_LGMRES = RegSolveAlg(1)

immutable RegSolveCtrl{T<:ElFloatType}
    alg::RegSolveAlg
    relTol::T
    relTolRefine::T
    maxIts::ElInt
    maxRefineIts::ElInt
    restart::ElInt
    progress::ElBool
    time::ElBool
end

function RegSolveCtrl{T<:ElFloatType}(::Type{T};
                    alg = REG_SOLVE_FGMRES,
                    relTol = eps(T)^0.5,
                    relTolRefine = eps(T)^0.8,
                    maxIts = 4,
                    maxRefineIts = 2,
                    restart = 4,
                    progress = false,
                    time = false)

    RegSolveCtrl{T}(RegSolveAlg(alg),
        T(relTol),
        T(relTolRefine),
        ElInt(maxIts),
        ElInt(maxRefineIts),
        ElInt(restart),
        ElBool(progress),
        ElBool(time))
end

for (ext, elty) in (("_s", :Float32), ("_d", :Float64), ("_c", :Complex64), ("_z", :Complex128))
    @eval begin
        function svdvals(A::DistMatrix{$elty})
            s = DistMatrix($elty)
            ccall(($(string("ElSingularValues", ext)), libEl), Void,
                (Ptr{Void}, Ptr{Void}),
                A.obj, s.obj)
            return s
        end
    end
end
