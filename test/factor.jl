
using Elemental, Test, Random
Random.seed!(1)

@testset "factor" begin
  @testset "qr!" begin
    N = 10 
    M = 9
    
    A = rand(ComplexF64, N, M)
    b = rand(ComplexF64, N)
    
    A1 = Elemental.Matrix(ComplexF64)
    Elemental.resize!(A1, size(A)...);
    A1 .= A
    
    qrA = Elemental._qr!(A1)
    
    b0 = Elemental.Matrix(ComplexF64)
    
    Elemental.resize!(b0, length(b), 1);
    b0 .= b
    
    x = A \ b
    #@show A'*A * x .- A' *b
    x1 = Vector(Matrix(qrA \ b0)[:])
    @test isapprox(x1, x)
  end
  @testset "lq!" begin
    N = 9
    M = 10
    
    A = rand(ComplexF64, N, M)
    b = rand(ComplexF64, N)
    
    A1 = Elemental.Matrix(ComplexF64)
    Elemental.resize!(A1, size(A)...);
    A1 .= A
    
    lqA = Elemental._lq!(A1)
    
    b0 = Elemental.Matrix(ComplexF64)
    
    Elemental.resize!(b0, length(b), 1);
    b0 .= b
    
    x = A \ b
    #@show A'*A * x .- A' *b
    x1 = Vector(Matrix(lqA \ b0)[:])
    @test isapprox(x1, x)
  end
  @testset "lu!" begin
    N = 10 
    M = 10
    
    A = rand(ComplexF64, N, M)
    b = rand(ComplexF64, N)
    
    A1 = Elemental.Matrix(ComplexF64)
    Elemental.resize!(A1, size(A)...);
    A1 .= A
    
    luA = Elemental._lu!(A1)
    
    b0 = Elemental.Matrix(ComplexF64)
    
    Elemental.resize!(b0, length(b), 1);
    b0 .= b
    
    x = A \ b
    #@show A'*A * x .- A' *b
    x1 = Vector(Matrix(luA \ b0)[:])
    @show size(x1)
    @test isapprox(x1, x)
  end
  @testset "cholesky!" begin
    N = 10 
    M = 10
    
    A = rand(ComplexF64, N, M)
    A .+= A'
    A .+= 10 .* I(N)
    b = rand(ComplexF64, N)
    
    A1 = Elemental.Matrix(ComplexF64)
    Elemental.resize!(A1, size(A)...);
    A1 .= A
    
    chA = Elemental._cholesky!(A1)
    
    b0 = Elemental.Matrix(ComplexF64)
    
    Elemental.resize!(b0, length(b), 1);
    b0 .= b
    
    x = A \ b
    #@show A'*A * x .- A' *b
    x1 = Vector(Matrix(chA \ b0)[:])
    @show size(x1)
    @test isapprox(x1, x)
  end


end

#A2 = Elemental.Matrix(ComplexF64)
#Elemental.resize!(A2, size(A)...);
#A2 .= A
#b1 = Elemental.Matrix(ComplexF64)
#Elemental.resize!(b1, length(b), 1);
#b1 .= b
#qrcp = Elemental._qrcp!(A2)
#
#x2 = Vector(Matrix(qrcp \ b1)[:])
#@show x
#y = real.(x2)
#@show y
#@test isapprox(x2, x)



