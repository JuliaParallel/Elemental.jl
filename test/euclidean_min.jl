using Test
using Elemental

A = Elemental.DistMatrix(Float32)
B = Elemental.DistMatrix(Float32)
X = Elemental.DistMatrix(Float32)

copy!(A, Float32[2 1; 1 2])
copy!(B, Float32[4, 5])

Elemental.leastSquares!(A, B, X)
@test isapprox(Array(X), [1, 2])

Elemental.ridge!(A, B, 0f0, X)
@test isapprox(Array(X), [1, 2])