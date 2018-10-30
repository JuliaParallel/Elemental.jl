for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:ComplexF32, :c),
                    (:ComplexF64, :z))

    # Distributed sparse gemv
    @eval begin
        function LinearAlgebra.mul!(y::DistMultiVec{$elty}, A::DistSparseMatrix{$elty}, x::DistMultiVec{$elty}, α::$elty, β::$elty)
            ElError(ccall(($(string("ElMultiplyDist_", ext)), libEl), Cuint,
                (Cint, $elty, Ptr{Cvoid}, Ptr{Cvoid}, $elty, Ptr{Cvoid}),
                NORMAL, α, A.obj, x.obj, β, y.obj))
            return y
        end
        function LinearAlgebra.mul!(y::DistMultiVec{$elty}, adjA::Adjoint{<:Any,DistSparseMatrix{$elty}}, x::DistMultiVec{$elty}, α::$elty, β::$elty)
            ElError(ccall(($(string("ElMultiplyDist_", ext)), libEl), Cuint,
                (Cint, $elty, Ptr{Cvoid}, Ptr{Cvoid}, $elty, Ptr{Cvoid}),
                ADJOINT, α, parent(adjA).obj, x.obj, β, y.obj))
            return y
        end
        function LinearAlgebra.mul!(y::DistMultiVec{$elty}, trA::Transpose{<:Any,DistSparseMatrix{$elty}}, x::DistMultiVec{$elty}, α::$elty, β::$elty)
            ElError(ccall(($(string("ElMultiplyDist_", ext)), libEl), Cuint,
                (Cint, $elty, Ptr{Cvoid}, Ptr{Cvoid}, $elty, Ptr{Cvoid}),
                TRANSPOSE, α, parent(trA).obj, x.obj, β, y.obj))
            return y
        end
    end
end