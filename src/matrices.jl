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
            bernoulli(::Type{$mat{$elty}}, m::Integer, n::Integer = 1, p::Real = 0.5) =
                bernoulli!($mat($elty), m, n, p)

            # Gaussian
            function gaussian!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1,
                               mean::Number = 0, stddev::Number = 1)
                err = ccall(($(string("ElGaussian", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt, $elty, $relty),
                    A.obj, m, n, mean, stddev)
                err == 0 || throw(ElError(err))
                return A
            end
            gaussian(::Type{$mat{$elty}}, m::Integer, n::Integer = 1,
                mean::Number = 0, stddev::Number = 1) =
                    gaussian!($mat($elty), m, n, mean, stddev)

            # Ones
            function ones!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1)
                err = ccall(($(string("ElOnes", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt),
                    A.obj, m, n)
                err == 0 || throw(ElError(err))
                return A
            end
            ones(::Type{$mat{$elty}}, m::Integer, n::Integer = 1) = ones!($mat($elty), m, n)

            # Uniform
            function uniform!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1,
                              center::Number = 0, radius::Real = 1)
                err = ccall(($(string("ElUniform", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt, $elty, $relty),
                    A.obj, m, n, center, radius)
                err == 0 || throw(ElError(err))
                return A
            end
            uniform(::Type{$mat{$elty}}, m::Integer, n::Integer = 1, center::Number = 0, radius::Real = 1) =
                uniform!($mat($elty), m, n, center, radius)

            # Zeros
            function zeros!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1)
                err = ccall(($(string("ElZeros", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt, ElInt),
                    A.obj, m, n)
                err == 0 || throw(ElError(err))
                return A
            end
            zeros(::Type{$mat{$elty}}, m::Integer, n::Integer = 1) = zeros!($mat($elty), m, n)
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
                foxLi(::Type{$mat{$elty}}, m::Integer, n::Integer = 1, ω::Real = 1.0) = foxLi!($mat($elty), m, n, ω)
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
            helmholtz(::Type{$mat{$elty}}, n::Integer...; shift::Number = 0) = helmholtz!($mat($elty), n..., shift = shift)
        end
    end
end

for (elty, ext) in ((:Complex64, :c),
                    (:Complex128, :z))

    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"))
        @eval begin
            # Fourier
            function fourier!(A::$mat{$elty}, n::Integer)
                err = ccall(($(string("ElFourier", sym, ext)), libEl), Cuint,
                    (Ptr{Void}, ElInt),
                    A.obj, n)
                err == 0 || throw(ElError(err))
                return A
            end
            fourier(::Type{$mat{$elty}}, n::Integer) = fourier!($mat($elty), n)
        end
    end
end

