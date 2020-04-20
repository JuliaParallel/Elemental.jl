using LinearAlgebra, Elemental, Test

m, n = 100, 80
A = Elemental.Matrix(Float64)
Elemental.gaussian!(A, m, n)
U_Elemental, s_Elemental, V_Elemental = svd(A)
U_LAPACK, s_LAPACK, V_LAPACK = svd(Matrix(A))
@test abs.(Matrix(U_Elemental)'*U_LAPACK) ≈ Matrix(I, n, n)
@test Matrix(s_Elemental) ≈ s_LAPACK
@test abs.(Matrix(V_Elemental)'*V_LAPACK) ≈ Matrix(I, n, n)
