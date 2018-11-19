const RegSolveAlg = Cuint

const REG_SOLVE_FGMRES = RegSolveAlg(0)
const REG_SOLVE_LGMRES = RegSolveAlg(1)

struct RegSolveCtrl{T<:ElFloatType}
    alg::RegSolveAlg
    relTol::T
    relTolRefine::T
    maxIts::ElInt
    maxRefineIts::ElInt
    restart::ElInt
    progress::ElBool
    time::ElBool
end

function RegSolveCtrl(::Type{T};
                    alg = REG_SOLVE_FGMRES,
                    relTol = eps(T)^0.5,
                    relTolRefine = eps(T)^0.8,
                    maxIts = 4,
                    maxRefineIts = 2,
                    restart = 4,
                    progress = false,
                    time = false) where {T<:ElFloatType}

    RegSolveCtrl{T}(RegSolveAlg(alg),
        T(relTol),
        T(relTolRefine),
        ElInt(maxIts),
        ElInt(maxRefineIts),
        ElInt(restart),
        ElBool(progress),
        ElBool(time))
end

mutable struct Permutation
    obj::Ptr{Cvoid}
end

function destroy(P::Permutation)
    ElError(ccall(("ElPermutationDestroy", libEl), Cuint,
        (Ptr{Cvoid},),
        P.obj))
    return nothing
end

function Permutation()
    obj = Ref{Ptr{Cvoid}}(0)
    ElError(ccall(("ElPermutationCreate", libEl), Cuint,
        (Ref{Ptr{Cvoid}},),
        obj))
    P = Permutation(obj[])
    finalizer(destroy, P)
    return P
end

mutable struct DistPermutation
    obj::Ptr{Cvoid}
end

function destroy(P::DistPermutation)
    ElError(ccall(("ElDistPermutationDestroy", libEl), Cuint,
        (Ptr{Cvoid},),
        P.obj))
    return nothing
end

function DistPermutation(grid::Grid = DefaultGrid[])
    obj = Ref{Ptr{Cvoid}}(0)
    ElError(ccall(("ElDistPermutationCreate", libEl), Cuint,
        (Ref{Ptr{Cvoid}}, Ptr{Cvoid}),
        obj, grid.obj))
    P = DistPermutation(obj[])
    finalizer(destroy, P)
    return P
end

for mattype in ("", "Dist")
    mat = Symbol(mattype, "Matrix")
    _p  = Symbol(mattype, "Permutation")

    for (elty, ext) in ((:Float32, :s),
                        (:Float64, :d),
                        (:ComplexF32, :c),
                        (:ComplexF64, :z))
        @eval begin

            function _cholesky!(uplo::UpperOrLower, A::$mat{$elty})
                ElError(ccall(($(string("ElCholesky", mattype, "_", ext)), libEl), Cuint,
                    (UpperOrLower, Ptr{Cvoid}),
                    uplo, A.obj))
                return A
            end

            function _lu!(A::$mat{$elty})
                p = $_p()
                ElError(ccall(($(string("ElLUPartialPiv", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}),
                    A.obj, p.obj))
                return A, p
            end
        end
    end
end
