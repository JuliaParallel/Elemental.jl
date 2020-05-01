using Elemental, TSVD, LinearAlgebra, Test
using Random
A = Elemental.DistMatrix(Float64)
Elemental.gaussian!(A, 500, 200)

# Warning! If seed is not set, each worker will end up with a different initial vector
# making the Lanczos processes inconsistent
Random.seed!(123)
vals_Elemental = tsvd(A, 5)[2]
localA = Array(A)
vals_LAPACK    = svdvals(localA)[1:5]
@test vals_Elemental ≈ vals_LAPACK
