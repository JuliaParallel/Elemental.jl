using Elemental

A = Elemental.DistSparseMatrix(Float64, 3, 3)

@show A

@show Elemental.destroy(A)