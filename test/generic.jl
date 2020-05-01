using Test
using Elemental

for T in (Float32, Float64, Complex{Float32}, Complex{Float64})
    A = Elemental.DistMatrix(T)
    Elemental.gaussian!(A, 10)
    @test convert(Elemental.DistMatrix{T}, ones(T, 5)) == ones(5,1)
    B = Elemental.DistMatrix(T)
    Array(copyto!(B, T[2 1; 1 2])) == T[2 1; 1 2]
end