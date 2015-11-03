using Base.Test
using Elemental
using DistributedArrays

A = drandn(50,50)
Al = convert(Array, A)
B = drandn(50,10)
Bl = convert(Array, B)

@test Al\Bl ≈ A\B
@test logdet(Al'Al) ≈ logdet(A'A)
@test svdvals(Al) ≈ Elemental.svdvals(A)
