using Test
using Elemental
using LinearAlgebra

m, n = 10, 10

for T in (Float32, Float64, Complex{Float32}, Complex{Float64})
    for mat in (Elemental.Matrix, Elemental.DistMatrix)
        A = mat(T)
        Elemental.gaussian!(A, m, n)

        @test opnorm(A, 1)   ≈ opnorm(T[A[i,j] for i = 1:m, j = 1:n], 1)
        @test opnorm(A)      ≈ opnorm(T[A[i,j] for i = 1:m, j = 1:n])
        @test opnorm(A, Inf) ≈ opnorm(T[A[i,j] for i = 1:m, j = 1:n], Inf)
    end
end