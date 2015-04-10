type DistMatrix{T} <: ElementalMatrix{T}
	obj::Ptr{Void}
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function DistMatrix(::Type{$elty}, colDist = EL_MC, rowDist = EL_MR, grid = Grid())
            obj = Ref{Ptr{Void}}(C_NULL)
            err = ccall(($(string("ElDistMatrixCreateSpecific_", ext)), libEl), Cuint,
                (Cint, Cint, Ptr{Void}, Ref{Ptr{Void}}),
                colDist, rowDist, grid.obj, obj)
            err == 0 || error("something is wrong here!")
            return DistMatrix{$elty}(obj[])
        end
    end
end

DistMatrix() = DistMatrix(Float64)

similar{T}(A::DistMatrix{T}) = DistMatrix(T) # This might be wrong. Should consider how to extract distributions properties of A

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function Grid(A::DistMatrix{$elty})
            g = Grid()
            err = ccall(($(string("ElDistMatrixGrid_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{Ptr{Void}}),
                A.obj, Ref{Ptr{Void}}(g.obj))
            err == 0 || error("something is wrong here!")
            return g
        end
    end
end
