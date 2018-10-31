using Elemental
using Test
using LinearAlgebra: eigvals

@testset "generel eigenvalues (Schur) with eltype: $elty" for elty in (Float32, Float64, Complex{Float32}, Complex{Float64})
    n = 10
    A = Elemental.DistMatrix(elty)
    Elemental.gaussian!(A, n, n)
    elvals = Elemental.eigvalsGeneral(A)
    lavals = eigvals(Array(A))
    @test sort(abs.(vec(Array(elvals)))) ≈ sort(abs.(lavals))
end