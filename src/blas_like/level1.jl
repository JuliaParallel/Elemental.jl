for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))
    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"),
                       (:DistMultiVec, "DistMultiVec_"))
        @eval begin
            function nrm2(x::$mat{$elty})
                nm = Ref{$relty}(0)
                err = ccall(($(string("ElNrm2", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ref{$relty}),
                    x.obj, nm)
                err == 0 || error("something is wrong here!")
                return nm[]
            end
        end
    end

    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"),
                       (:DistMultiVec, "DistMultiVec_"))
        @eval begin
            function copy!(src::$mat{$elty}, dest::$mat{$elty})
                err = ccall(($(string("ElCopy", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}),
                    src.obj, dest.obj)
                err == 0 || error("something is wrong here!")
                dest
            end
        end
    end
end
copy(A::ElementalMatrix) = copy!(A, similar(A))
