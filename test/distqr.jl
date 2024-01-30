using MPI, MPIClusterManagers, Distributed

man = MPIManager(np = 2);

addprocs(man);

@everywhere using LinearAlgebra, Elemental

const M = 400
const N = 300

@mpi_do man M = @fetchfrom 1 M
@mpi_do man N = @fetchfrom 1 N

const Ahost = rand(Float64, M, N)
const bhost = rand(Float64, M)

@mpi_do man Aall = @fetchfrom 1 Ahost
@mpi_do man ball = @fetchfrom 1 bhost

@mpi_do man A = Elemental.DistMatrix(Float64);
@mpi_do man b = Elemental.DistMatrix(Float64);

@mpi_do man A = Elemental.resize!(A, M, N);
@mpi_do man b = Elemental.resize!(b, M);

@mpi_do man copyto!(A, Aall)
@mpi_do man copyto!(b, ball)

@mpi_do man qrA = Elemental.qr!(A);

@mpi_do man x = qrA \ b;

@everywhere function localpart(A::Elemental.DistMatrix{T}) where T
  buffer = zeros(T, Elemental.localHeight(A), Elemental.localWidth(A))
  return localpart!(buffer, A)
end

@everywhere function localpart!(buffer, A::Elemental.DistMatrix)
  @assert size(buffer) == (Elemental.localHeight(A), Elemental.localWidth(A))
  for j in 1:Elemental.localWidth(A), i in 1:Elemental.localHeight(A)
    buffer[i, j] = Elemental.getLocal(A, i, j)
  end
  return buffer
end

@mpi_do man localx = zeros(Float64, Elemental.localHeight(x), Elemental.localWidth(x))
@mpi_do man copyto!(localx, localpart(x))

using Test
x = vcat((fetch(@spawnat p localx)[:] for p in workers())...)
@testset "qr" begin
  @test x ≈ Ahost \ bhost
end
