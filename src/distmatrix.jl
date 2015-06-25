type DistMatrix{T} <: ElementalMatrix{T}
	obj::Ptr{Void}
end

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function DistMatrix(::Type{$elty}, colDist = EL_MC, rowDist = EL_MR, grid = Grid())
            obj = Ref{Ptr{Void}}(C_NULL)
            err = ccall(($(string("ElDistMatrixCreateSpecific_", ext)), libEl), Cuint,
                (Cint, Cint, Ptr{Void}, Ref{Ptr{Void}}),
                colDist, rowDist, grid.obj, obj)
            err == 0 || throw(ElError(err))
            return DistMatrix{$elty}(obj[])
        end
    end
end

DistMatrix() = DistMatrix(Float64)

similar{T}(A::DistMatrix{T}) = DistMatrix(T) # This might be wrong. Should consider how to extract distributions properties of A

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function Grid(A::DistMatrix{$elty})
            g = Grid()
            err = ccall(($(string("ElDistMatrixGrid_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{Ptr{Void}}),
                A.obj, Ref{Ptr{Void}}(g.obj))
            err == 0 || throw(ElError(err))
            return g
        end

        function reserve{$elty}(A::DistMatrix{$elty}, numEntries::Integer)
            err = ccall(($(string("ElDistMatrixReserve_", ext)), libEl), Cuint,
              (Ptr{Void}, ElInt),
              A.obj, numEntries)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function queueUpdate{$elty}(A::DistMatrix{$elty}, i::Integer, j::Integer, value::$elty)
            err = ccall(($(string("ElDistMatrixQueueUpdate_", ext)), libEl), Cuint,
              (Ptr{Void}, ElInt, ElInt, $elty),
              A.obj, i, j, value)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function processQueues{$elty}(A::DistMatrix{$elty})
          err = ccall(($(string("ElDistMatrixProcessQueues_", ext)), libEl), Cuint,
            (Ptr{Void}), A.obj)
          err == 0 || throw(ElError(err))
          return nothing
        end
    end
end
