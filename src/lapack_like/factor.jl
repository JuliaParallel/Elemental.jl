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
        end
    end
end

for mattype in ("", "Dist")
  mat = Symbol(mattype, "Matrix")
  _p  = Symbol(mattype, "Permutation")

  # TODO - fix QRColPiv
  #QRColPivStructName = Symbol("QRColPiv$(string(mattype))")
  QRStructName = Symbol("QR$(string(mattype))")
  LQStructName = Symbol("LQ$(string(mattype))")
  LUStructName = Symbol("LU$(string(mattype))")

  @eval begin
  #struct $QRColPivStructName{T,U<:Real}
  #  A::$mat{T}
  #  t::$mat{T}
  #  d::$mat{U}
  #  p::$_p
  #  orientation::Ref{Orientation}
  #end
  #function $QRColPivStructName(A, t, d, p)
  #  return $QRColPivStructName(A, t, d, p, Ref(NORMAL::Orientation))
  #end

  struct $QRStructName{T,U<:Real}
    A::$mat{T}
    t::$mat{T}
    d::$mat{U}
    orientation::Ref{Orientation}
  end
  function $QRStructName(A, t, d)
    return $QRStructName(A, t, d, Ref(NORMAL::Orientation))
  end

  struct $LQStructName{T, U<:Real}
    A::$mat{T}
    householderscalars::$mat{T}
    signature::$mat{U}
    orientation::Ref{Orientation}
  end
  function $LQStructName(A, householderscalars, signature)
    return $LQStructName(A, householderscalars, signature, Ref(NORMAL::Orientation))
  end

  struct $LUStructName{T}
    A::$mat{T}
    p::$_p
    orientation::Ref{Orientation}
  end
  function $LUStructName(A, p)
    return $LUStructName(A, p, Ref(NORMAL::Orientation))
  end

  end

  for (elty, ext) in ((:Float32, :s),
                      (:Float64, :d),
                      (:ComplexF32, :c),
                      (:ComplexF64, :z))

    @eval begin

    function _lu!(A::$mat{$elty})
      p = $_p()
      ElError(ccall(($(string("ElLUPartialPiv", mattype, "_", ext)), libEl), Cuint,
        (Ptr{Cvoid}, Ptr{Cvoid}),
        A.obj, p.obj))
      return $LUStructName(A, p)
    end
    function LinearAlgebra.:\(lu::$LUStructName{$elty}, b::$mat{$elty})
      x = deepcopy(b)#$mat($elty)
      ElError(ccall(($(string("ElSolveAfterLU", mattype, "_", ext)), libEl), Cuint,
        (Orientation, Ptr{Cvoid}, Ptr{Cvoid}),
        lu.orientation[], lu.A.obj, x.obj))
      return x
    end

    #function _qrcp!(A::$mat{$elty})
    #  t = $mat($elty)
    #  d = $mat(real($elty))
    #  p = $_p()
    #  ElError(ccall(($(string("ElQRColPiv", mattype, "_", ext)), libEl), Cuint,
    #    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
    #    A.obj, t.obj, d.obj, p.obj))
    #  return $QRColPivStructName(A, t, d, p)
    #end
    #function LinearAlgebra.:\(qr::$QRColPivStructName{$elty}, b::$mat{$elty})
    #  x = $mat($elty)
    #  ElError(ccall(($(string("ElSolveAfterQR", mattype, "_", ext)), libEl), Cuint,
    #    (Orientation, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
    #    qr.orientation[], qr.A.obj, qr.t.obj, qr.d.obj, b.obj, x.obj))
    #  ElError(ccall(($(string("El", mattype, "PermutationPermuteRows", "_", ext)), libEl), Cuint,
    #    (Ptr{Cvoid}, Ptr{Cvoid}, ElInt),
    #     qr.p.obj, x.obj, 0))
    #  return x
    #end

    function _qr!(A::$mat{$elty})
      t = $mat($elty)
      d = $mat(real($elty))
      ElError(ccall(($(string("ElQR", mattype, "_", ext)), libEl), Cuint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        A.obj, t.obj, d.obj))
      return $QRStructName(A, t, d)
    end

    function LinearAlgebra.:\(qr::$QRStructName{$elty}, b::$mat{$elty})
      x = $mat($elty)
      ElError(ccall(($(string("ElSolveAfterQR", mattype, "_", ext)), libEl), Cuint,
        (Orientation, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        qr.orientation[], qr.A.obj, qr.t.obj, qr.d.obj, b.obj, x.obj))
      return x
    end

    function _lq!(A::$mat{$elty})
      householderscalars = $mat($elty)
      signature = $mat(real($elty))
      ElError(ccall(($(string("ElLQ", mattype, "_", ext)), libEl), Cuint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        A.obj, householderscalars.obj, signature.obj))
      return $LQStructName(A, householderscalars, signature)
    end

    function LinearAlgebra.:\(lq::$LQStructName{$elty}, b::$mat{$elty})
      x = $mat($elty)
      ElError(ccall(($(string("ElSolveAfterLQ", mattype, "_", ext)), libEl), Cuint,
        (Orientation, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        lq.orientation[], lq.A.obj, lq.householderscalars.obj,
        lq.signature.obj, b.obj, x.obj))
      return x
    end

    end
  end
end
