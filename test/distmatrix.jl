using Base.Test
using Elemental

for T in (Float32, Float64, Complex{Float32}, Complex{Float64})
    A = Elemental.DistMatrix(T)
    Elemental.gaussian!(A, 10)
    @test isa(similar(A), Elemental.DistMatrix{T})
    @test isa(similar(A, Elemental.ElInt), Elemental.DistMatrix{Elemental.ElInt})
    @test isa(similar(A, Float32), Elemental.DistMatrix{Float32})
    @test isa(similar(A, Elemental.ElInt, (5,5)), Elemental.DistMatrix{Elemental.ElInt})
    @test isa(similar(A, Float32, (5,5)), Elemental.DistMatrix{Float32})
end
