for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))
    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"),
                       (:DistMultiVec, "DistMultiVec_"))
        @eval begin
            function axpy!(α::$elty, x::$mat{$elty}, y::$mat{$elty})
                err = ccall(($(string("ElAxpy", sym, ext)), libEl), Cuint,
                    ($elty, Ptr{Void}, Ptr{Void}),
                    α, x.obj, y.obj)
                err == 0 || throw(ElError(err))
                return y
            end

            function copy!(src::$mat{$elty}, dest::$mat{$elty})
                err = ccall(($(string("ElCopy", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}),
                    src.obj, dest.obj)
                err == 0 || throw(ELError(err))
                dest
            end

            function dot(x::$mat{$elty}, y::$mat{$elty})
                rval = Ref{$elty}(0)
                err = ccall(($(string("ElDot", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}, Ref{$elty}),
                    x.obj, y.obj, rval)
                err == 0 || throw(ElError(err))
                return rval[]
            end

            function fill!(x::$mat{$elty}, val::Number)
                err = ccall(($(string("ElFill", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, $elty),
                    x.obj, $elty(val))
                err == 0 || throw(ElError(err))
                return x
            end

            # Horizontal concatenation
            # C := [A, B]
            function hcat!(A::$mat{$elty}, B::$mat{$elty}, C::$mat{$elty})
                err = ccall(($(string("ElHCat", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}, Ptr{Void}),
                    A.obj, B.obj, C.obj)
                err == 0 || throw(ElError(err))
                return C
            end
            hcat(A::$mat{$elty}, B::$mat{$elty}) = hcat!(A, B, $mat($elty))

            function nrm2(x::$mat{$elty})
                rval = Ref{$relty}(0)
                err = ccall(($(string("ElNrm2", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ref{$relty}),
                    x.obj, rval)
                err == 0 || throw(ElError(err))
                return rval[]
            end

            function scale!(x::$mat{$elty}, val::Number)
                err = ccall(($(string("ElScale", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, $elty),
                    x.obj, $elty(val))
                err == 0 || throw(ElError(err))
                return x
            end

            # Vertical concatenation
            # C := [A; B]
            function vcat!(A::$mat{$elty}, B::$mat{$elty}, C::$mat{$elty})
                err = ccall(($(string("ElVCat", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ptr{Void}, Ptr{Void}),
                    A.obj, B.obj, C.obj)
                err == 0 || throw(ElError(err))
                return C
            end
            vcat(A::$mat{$elty}, B::$mat{$elty}) = vcat!(A, B, $mat($elty))
        end
    end
end

copy(A::ElementalMatrix) = copy!(A, similar(A))
length(A::ElementalMatrix) = prod(size(A))
