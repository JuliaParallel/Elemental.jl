for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:ComplexF32, :Float32, :c),
                           (:ComplexF64, :Float64, :z))
    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"),
                       (:DistMultiVec, "DistMultiVec_"))
        @eval begin
            function LinearAlgebra.axpy!(α::$elty, x::$mat{$elty}, y::$mat{$elty})
                ElError(ccall(($(string("ElAxpy", sym, ext)), libEl), Cuint,
                    ($elty, Ptr{Cvoid}, Ptr{Cvoid}),
                    α, x.obj, y.obj))
                return y
            end

            # Which is opposite Julia's copy! so we call it _copy! to avoid confusion
            function _copy!(src::$mat{$elty}, dest::$mat{$elty})
                ElError(ccall(($(string("ElCopy", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}),
                    src.obj, dest.obj))
                dest
            end

            function LinearAlgebra.dot(x::$mat{$elty}, y::$mat{$elty})
                rval = Ref{$elty}(0)
                ElError(ccall(($(string("ElDot", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ref{$elty}),
                    x.obj, y.obj, rval))
                return rval[]
            end

            function fill!(x::$mat{$elty}, val::Number)
                ElError(ccall(($(string("ElFill", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, $elty),
                    x.obj, $elty(val)))
                return x
            end

            # Horizontal concatenation
            # C := [A, B]
            function hcat!(A::$mat{$elty}, B::$mat{$elty}, C::$mat{$elty})
                ElError(ccall(($(string("ElHCat", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                    A.obj, B.obj, C.obj))
                return C
            end
            hcat(A::$mat{$elty}, B::$mat{$elty}) = hcat!(A, B, $mat($elty))

            function nrm2(x::$mat{$elty})
                rval = Ref{$relty}(0)
                ElError(ccall(($(string("ElNrm2", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ref{$relty}),
                    x.obj, rval))
                return rval[]
            end

            function scale!(x::$mat{$elty}, val::Number)
                ElError(ccall(($(string("ElScale", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, $elty),
                    x.obj, $elty(val)))
                return x
            end

            # Vertical concatenation
            # C := [A; B]
            function vcat!(A::$mat{$elty}, B::$mat{$elty}, C::$mat{$elty})
                ElError(ccall(($(string("ElVCat", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                    A.obj, B.obj, C.obj))
                return C
            end
            vcat(A::$mat{$elty}, B::$mat{$elty}) = vcat!(A, B, $mat($elty))
        end
    end
end
