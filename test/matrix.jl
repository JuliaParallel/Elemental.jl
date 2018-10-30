using Test
using Elemental

for T in (Float32, Float64, Complex{Float32}, Complex{Float64})
    A = Elemental.Matrix(T)
    Elemental.gaussian!(A, 10)
    @test isa(similar(A), Elemental.Matrix{T})
    @test isa(similar(A, Elemental.ElInt), Elemental.Matrix{Elemental.ElInt})
    @test isa(similar(A, Float32), Elemental.Matrix{Float32})
    @test isa(similar(A, Elemental.ElInt, (5,5)), Elemental.Matrix{Elemental.ElInt})
    @test isa(similar(A, Float32, (5,5)), Elemental.Matrix{Float32})
end
