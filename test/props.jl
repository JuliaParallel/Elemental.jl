using Base.Test
using Elemental

m, n = 10, 10

for T in (Float32, Float64, Complex{Float32}, Complex{Float64})
    for mat in (Elemental.Matrix, Elemental.DistMatrix)
        A = mat(T)
        Elemental.gaussian!(A, m, n)

        @test norm(A, 1) ≈ norm(T[A[i,j] for i = 1:m, j = 1:n], 1)
        @test norm(A) ≈ norm(T[A[i,j] for i = 1:m, j = 1:n])
        @test norm(A, Inf) ≈ norm(T[A[i,j] for i = 1:m, j = 1:n], Inf)
        @test countnz(A) ≈ countnz(T[A[i,j] for i = 1:m, j = 1:n])
    end
end