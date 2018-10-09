for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:ComplexF32, :Float32, :c),
                           (:ComplexF64, :Float64, :z))

    # Distributed sparse gemv
    for (trans, elenum) in (("", :NORMAL), ("t", :TRANSPOSE), ("c", :ADJOINT))

        f = Symbol("A", trans, "_mul_B!")

        @eval begin
            function ($f)(α::$elty, A::DistSparseMatrix{$elty}, x::DistMultiVec{$elty}, β::$elty, y::DistMultiVec{$elty})
                ElError(ccall(($(string("ElMultiplyDist_", ext)), libEl), Cuint,
                    (Cint, $elty, Ptr{Cvoid}, Ptr{Cvoid}, $elty, Ptr{Cvoid}),
                    $elenum, α, A.obj, x.obj, β, y.obj))
                return y
            end
        end
    end
end