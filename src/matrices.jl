for (elty, relty, ext) in ((:ElInt, :ElInt, :i),
                           (:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:ComplexF32, :Float32, :c),
                           (:ComplexF64, :Float64, :z))

    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"),
                       (:DistMultiVec, "DistMultiVec_"))
        @eval begin
            # Bernoulli
            function bernoulli!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1, p::Real = 0.5)
                ElError(ccall(($(string("ElBernoulli", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, ElInt, ElInt, Float64),
                    A.obj, m, n, Float64(p)))
                return A
            end
            bernoulli(::Type{$mat{$elty}}, m::Integer, n::Integer = 1, p::Real = 0.5) =
                bernoulli!($mat($elty), m, n, p)

            # Gaussian
            function gaussian!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1,
                               mean::Number = 0, stddev::Number = 1)
                ElError(ccall(($(string("ElGaussian", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, ElInt, ElInt, $elty, $relty),
                    A.obj, m, n, mean, stddev))
                return A
            end
            gaussian(::Type{$mat{$elty}}, m::Integer, n::Integer = 1,
                mean::Number = 0, stddev::Number = 1) =
                    gaussian!($mat($elty), m, n, mean, stddev)

            # Ones
            function ones!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1)
                ElError(ccall(($(string("ElOnes", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, ElInt, ElInt),
                    A.obj, m, n))
                return A
            end
            ones(::Type{$mat{$elty}}, m::Integer, n::Integer = 1) = ones!($mat($elty), m, n)

            # Uniform
            function uniform!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1,
                              center::Number = 0, radius::Real = 1)
                ElError(ccall(($(string("ElUniform", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, ElInt, ElInt, $elty, $relty),
                    A.obj, m, n, center, radius))
                return A
            end
            uniform(::Type{$mat{$elty}}, m::Integer, n::Integer = 1, center::Number = 0, radius::Real = 1) =
                uniform!($mat($elty), m, n, center, radius)

            # Zeros
            function zeros!(A::$mat{$elty}, m::Integer = size(A, 1), n::Integer = 1)
                ElError(ccall(($(string("ElZeros", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, ElInt, ElInt),
                    A.obj, m, n))
                return A
            end
            zeros(::Type{$mat{$elty}}, m::Integer, n::Integer = 1) = zeros!($mat($elty), m, n)
        end

        if elty == :ComplexF32 || elty == :ComplexF64
            # Uniform
            @eval begin
                function foxLi!(A::$mat{$elty}, n::Integer = size(A, 1), ω::Real = 1.0)
                    ElError(ccall(($(string("ElFoxLi", sym, ext)), libEl), Cuint,
                        (Ptr{Cvoid}, ElInt, $relty),
                        A.obj, n, ω))
                    return A
                end
                foxLi(::Type{$mat{$elty}}, m::Integer, n::Integer = 1, ω::Real = 1.0) = foxLi!($mat($elty), m, n, ω)
            end
        end
    end
end

for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:ComplexF32, :Float32, :c),
                           (:ComplexF64, :Float64, :z))

    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"),
                       (:SparseMatrix, "Sparse_"),
                       (:DistSparseMatrix, "DistSparse_"))
        @eval begin
            # Helmholtz
            function helmholtz!(A::$mat{$elty}, nx::Integer; shift::Number = 0)
                ElError(ccall(($(string("ElHelmholtz1D", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, ElInt, $elty),
                    A.obj, nx, shift))
                return A
            end

            function helmholtz!(A::$mat{$elty}, nx::Integer, ny::Integer; shift::Number = 0)
                ElError(ccall(($(string("ElHelmholtz2D", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, ElInt, ElInt, $elty),
                    A.obj, nx, ny, shift))
                return A
            end

            function helmholtz!(A::$mat{$elty}, nx::Integer, ny::Integer, nz::Integer; shift::Number = 0)
                ElError(ccall(($(string("ElHelmholtz3D", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, ElInt, ElInt, ElInt, $elty),
                    A.obj, nx, ny, nz, shift))
                return A
            end
            helmholtz(::Type{$mat{$elty}}, n::Integer...; shift::Number = 0) = helmholtz!($mat($elty), n..., shift = shift)
        end
    end
end

for (elty, ext) in ((:ComplexF32, :c),
                    (:ComplexF64, :z))

    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"))
        @eval begin
            # Fourier
            function fourier!(A::$mat{$elty}, n::Integer)
                ElError(ccall(($(string("ElFourier", sym, ext)), libEl), Cuint,
                    (Ptr{Cvoid}, ElInt),
                    A.obj, n))
                return A
            end
            fourier(::Type{$mat{$elty}}, n::Integer) = fourier!($mat($elty), n)
        end
    end
end

