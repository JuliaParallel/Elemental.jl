using Elemental, TSVD, LinearAlgebra, Test

A = Elemental.DistMatrix(Float64)
Elemental.gaussian!(A, 500, 200)
vals_Elemental = tsvd(A, 5)[2]
vals_LAPACK    = svdvals(convert(Array, A))[1:5]
@test vals_Elemental ≈ vals_LAPACK
