for (elty, relty, ext) in ((:ElInt, :ElInt, :i),
                           (:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))

    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"),
                       (:DistMultiVec, "DistMultiVec_"))
        @eval begin
            # Bernoulli
            function bernoulli!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1, p::Real = 0.5)
                err = ccall(($(string("ElBernoulli", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt, Float64),
                    A.obj, m, n, Float64(p))
                err == 0 || throw(ElError(err))
                return A
            end

            # Gaussian
            function gaussian!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1,
                               mean::Number = 0, stddev::Number = 1)
                err = ccall(($(string("ElGaussian", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt, $elty, $relty),
                    A.obj, m, n, mean, stddev)
                err == 0 || throw(ElError(err))
                return A
            end

            # Ones
            function ones!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1)
                err = ccall(($(string("ElOnes", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt),
                    A.obj, m, n)
                err == 0 || throw(ElError(err))
                return A
            end

            # Uniform
            function uniform!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1,
                              center::Number = 0, radius::Number = 1)
                err = ccall(($(string("ElUniform", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt, $elty, $relty),
                    A.obj, m, n, center, radius)
                err == 0 || throw(ElError(err))
                return A
            end

            # Zeros
            function zeros!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1)
                err = ccall(($(string("ElZeros", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt),
                    A.obj, m, n)
                err == 0 || throw(ElError(err))
                return A
            end
        end

        if elty == :Complex64 || elty == :Complex128
            # Uniform
            @eval begin
                function foxLi!(A::$mat{$elty}, n::Integer = size(A, 1), ω::Real = 1.0)
                    err = ccall(($(string("ElFoxLi", sym, ext)), libEl), Cuint,
                        (Ptr{Void}, ElInt, $relty),
                        A.obj, n, ω)
                    err == 0 || throw(ElError(err))
                    return A
                end
            end
        end
    end
end

for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))

    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"),
                       (:SparseMatrix, "Sparse_"),
                       (:DistSparseMatrix, "DistSparse_"))
        @eval begin
            # Helmholtz
            function helmholtz!(A::$mat{$elty}, nx::Integer; shift::Number = 0)
                err = ccall(($(string("ElHelmholtz1D", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, $elty),
                    A.obj, nx, shift)
                err == 0 || throw(ElError(err))
                return A
            end

            function helmholtz!(A::$mat{$elty}, nx::Integer, ny::Integer; shift::Number = 0)
                err = ccall(($(string("ElHelmholtz2D", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt, $elty),
                    A.obj, nx, ny, shift)
                err == 0 || throw(ElError(err))
                return A
            end

            function helmholtz!(A::$mat{$elty}, nx::Integer, ny::Integer, nz::Integer; shift::Number = 0)
                err = ccall(($(string("ElHelmholtz3D", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt, ElInt, $elty),
                    A.obj, nx, ny, nz, shift)
                err == 0 || throw(ElError(err))
                return A
            end
        end
    end
end


