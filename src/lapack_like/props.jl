immutable SafeProduct{T<:BlasReal}
    ρ::T
    κ::T
    n::ElInt
end

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

            function entrywiseNorm(A::$mat{$elty}, p::Real)
                rval = Ref{$relty}(0)
                err = ccall(($(string("ElEntrywiseNorm", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, $relty, Ref{$relty}),
                    A.obj, p, rval)
                err == 0 || throw(ElError(err))
                return rval[]
            end

            function infinityNorm(A::$mat{$elty})
                rval = Ref{$relty}(0)
                err = ccall(($(string("ElInfinityNorm", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ref{$relty}),
                    A.obj, rval)
                err == 0 || throw(ElError(err))
                return rval[]
            end

            function maxNorm(A::$mat{$elty})
                rval = Ref{$relty}(0)
                err = ccall(($(string("ElMaxNorm", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ref{$relty}),
                    A.obj, rval)
                err == 0 || throw(ElError(err))
                return rval[]
            end

            function oneNorm(A::$mat{$elty})
                rval = Ref{$relty}(0)
                err = ccall(($(string("ElOneNorm", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ref{$relty}),
                    A.obj, rval)
                err == 0 || throw(ElError(err))
                return rval[]
            end
        end
    end

    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"))
        @eval begin

            function safeHPDDeterminant(uplo::UpperOrLower, A::$mat{$elty})
                rval = Ref{SafeProduct{$relty}}()
                err = ccall(($(string("ElSafeHPDDeterminant", sym, ext)), libEl), Cuint,
                    (UpperOrLower, Ptr{Void}, Ref{SafeProduct{$relty}}),
                    uplo, A.obj, rval)
                err == 0 || throw(ElError(err))
                return rval[]
            end

            function twoNorm(A::$mat{$elty})
                rval = Ref{$relty}(0)
                err = ccall(($(string("ElTwoNorm", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ref{$relty}),
                    A.obj, rval)
                err == 0 || throw(ElError(err))
                return rval[]
            end

            function zeroNorm(A::$mat{$elty})
                rval = Ref{ElInt}(0)
                err = ccall(($(string("ElZeroNorm", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, Ref{ElInt}),
                    A.obj, rval)
                err == 0 || throw(ElError(err))
                return rval[]
            end
        end
    end
end

countnz(A::Union{Matrix,DistMatrix}) = Int(zeroNorm(A))

function norm(A::ElementalMatrix, p::Real)
    if p == 1
        return oneNorm(A)
    elseif p == 2
        return twoNorm(A)
    elseif p == Inf
        return infinityNorm(A)
    else
        throw(ArgumentError("value of p not supported yet"))
    end
end
