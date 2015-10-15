for (elty, relty, ext) in ((:Integer, :Integer, :i),
                           (:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))

    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"),
                       (:DistMultiVec, "DistMultiVec_"))
        # Ones
        @eval begin
            function ones!(A::$mat{$elty}, m::Integer, n::Integer)
                err = ccall(($(string("ElOnes", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt),
                    A.obj, m, n)
                err == 0 || throw(ElError(err))
                return A
            end
        end

        # Zeros
        @eval begin
            function zeros!(A::$mat{$elty}, m::Integer, n::Integer)
                err = ccall(($(string("ElZeros", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt),
                    A.obj, m, n)
                err == 0 || throw(ElError(err))
                return A
            end
        end

        # Gaussian
        @eval begin
            function gaussian!(A::$mat{$elty}, m::Integer, n::Integer,
                               mean::$elty = zero($elty), stddev::$relty = one($relty))
                err = ccall(($(string("ElGaussian", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt, $elty, $relty),
                    A.obj, m, n, mean, stddev)
                err == 0 || throw(ElError(err))
                return A
            end
        end

        # Uniform
        @eval begin
            function uniform!(A::$mat{$elty}, m::Integer, n::Integer,
                              center::$elty = zero($elty), radius::$relty = one($relty))
                err = ccall(($(string("ElUniform", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt, $elty, $relty),
                    A.obj, m, n, center, radius)
                err == 0 || throw(ElError(err))
                return A
            end
        end

        if elty == :Complex64 || elty == :Complex128
            # Uniform
            @eval begin
                function foxLi!(A::$mat{$elty}, n::Integer, omega::$relty)
                    err = ccall(($(string("ElFoxLi", sym, ext)), libEl), Cuint,
                        (Ptr{Void}, ElInt, $relty),
                        A.obj, n, omega)
                    err == 0 || throw(ElError(err))
                    return A
                end
            end
        end
    end
end
