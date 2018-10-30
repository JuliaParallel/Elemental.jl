using Test
using Elemental
using DistributedArrays
using LinearAlgebra

A  = drandn(50,50)
Al = Matrix(A)
B  = drandn(50,10)
Bl = Matrix(B)

@test inv(Al) ≈ inv(A)
@test Al\Bl ≈ A\B
@test logdet(Al'Al) ≈ logdet(A'A)
@test svdvals(Al) ≈ Elemental.svdvals(A)
