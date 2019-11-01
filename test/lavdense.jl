import Elemental
const El = Elemental
using LinearAlgebra: mul!
using Test

m = 500
n = 250
display = true
worldRank = El.MPI.commRank(El.MPI.CommWorld[])

function rectang(height::Integer, width::Integer)
    A = El.DistMatrix()
    El.uniform!(A, height, width)
    return A
end

A = rectang(m, n)
b = El.DistMatrix()
El.gaussian!(b, m, 1)

# if display
    # El.Display(A, "A")
    # El.Display(b, "b")
# end

# ctrl = El.LPAffineCtrl_d()
# ctrl.mehrotraCtrl.progress = True

# timeLAV = @elapsed x = El.lav(A, b, ctrl)
timeLAV = @elapsed x = El.lav(A, b)
if El.MPI.commRank(El.MPI.CommWorld[]) == 0
    println("LAV time: $timeLAV seconds")
end

# if display
    # El.Display( x, "x" )

bTwoNorm = El.nrm2(b)
bInfNorm = El.maxNorm(b)

r = copy(b)
mul!(r, A, x, -1.0, 1.)

# if display
    # El.Display(r, "r")
# end

rTwoNorm = El.nrm2(r)
rOneNorm = El.entrywiseNorm(r, 1.0)
if worldRank == 0
    println("|| b ||_2       = $bTwoNorm")
    println("|| b ||_oo      = $bInfNorm")
    println("|| A x - b ||_2 = $rTwoNorm")
    println("|| A x - b ||_1 = $rOneNorm")
end

timeLS = @elapsed xLS = El.leastSquares(A, b)

if worldRank == 0
    println("LS time: $timeLS seconds")
end
# if display
    # El.Display(xLS, "x_{LS}")
# end

rLS = copy(b)
mul!(rLS, A, xLS, -1.0, 1.0)

# if display:
    # El.Display(rLS, "A x_{LS} - b")
# end
rLSTwoNorm = El.nrm2(rLS)
rLSOneNorm = El.entrywiseNorm(rLS, 1.0)
if worldRank == 0
    println("|| A x_{LS} - b ||_2 = $rLSTwoNorm")
    println("|| A x_{LS} - b ||_1 = $rLSOneNorm")
end
# if display
    # El.Display(xLS, "x_{LS}")
# end

timeRidge = @elapsed xRidge = El.ridge(A, b, 0.0)

if worldRank == 0
    println("Ridge time: $timeRidge seconds")
end
# if display
    # El.Display(xRidge, "x_{Ridge}")
# end

rRidge = copy(b)
mul!(rRidge, A, xRidge, -1.0, 1.0)

# if display:
    # El.Display(rRidge, "A x_{Ridge} - b")
# end
rRidgeTwoNorm = El.nrm2(rRidge)
rRidgeOneNorm = El.entrywiseNorm(rRidge, 1.0)
if worldRank == 0
    println("|| A x_{Ridge} - b ||_2 = $rRidgeTwoNorm")
    println("|| A x_{Ridge} - b ||_1 = $rRidgeOneNorm")
end

for T in (Float32, Float64)
    A = El.DistMatrix(T)
    b = El.DistMatrix(T)
    copy!(A, T[2 1; 1 2])
    copy!(b, T[4, 5])
    x = Array(El.leastSquares(A, b))
    if worldRank == 0
        @test isapprox(x, T[1, 2])
    end
    x = Array(El.ridge(A, b, zero(T)))
    if worldRank == 0
        @test isapprox(x, T[1, 2])
    end
end

# Require the user to press a button before the figures are closed
# commSize = El.mpi.Size( El.mpi.COMM_WORLD() )
El.Finalize()
# if commSize == 1:
#   raw_input('Press Enter to exit')
