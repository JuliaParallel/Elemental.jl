for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))
    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"),
                       (:SparseMatrix, "Sparse_"),
                       (:DistSparseMatrix, "DistSparse_"),
                       (:DistMultiVec, "DistMultiVec_"))
        @eval begin
            function maxNorm(x::$mat{$elty})
                nm = Ref{$relty}(0)
                err = ccall(($(string("ElMaxNorm", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ref{$relty}),
                    x.obj, nm)
                err == 0 || error("something is wrong here!")
                return nm[]
            end
        end
    end

    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"),
                       (:SparseMatrix, "Sparse_"),
                       (:DistSparseMatrix, "DistSparse_"),
                       (:DistMultiVec, "DistMultiVec_"))
        @eval begin
            function entrywiseNorm(x::$mat{$elty}, p::Real)
                nm = Ref{$relty}(0)
                err = ccall(($(string("ElEntrywiseNorm", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, $relty, Ref{$relty}),
                    x.obj, p, nm)
                err == 0 || error("something is wrong here!")
                return nm[]
            end
        end
    end
end
