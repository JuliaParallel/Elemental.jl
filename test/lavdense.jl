import Elemental
const El = Elemental

using MPI

m = 500
n = 250
display = true
worldRank = MPI.Comm_rank(MPI.COMM_WORLD)

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
if MPI.Comm_rank(MPI.COMM_WORLD) == 0
    println("LAV time: $timeLAV seconds")
end

# if display
    # El.Display( x, "x" )

bTwoNorm = El.nrm2(b)
bInfNorm = El.maxNorm(b)

r = copy(b)
A_mul_B!(-1.0, A, x, 1., r)

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
A_mul_B!(-1.0, A, xLS, 1.0, rLS)

# if display:
    # El.Display(rLS, "A x_{LS} - b")
# end
rLSTwoNorm = El.nrm2(rLS)
rLSOneNorm = El.entrywiseNorm(rLS, 1.0)
if worldRank == 0
    println("|| A x_{LS} - b ||_2 = $rLSTwoNorm")
    println("|| A x_{LS} - b ||_1 = $rLSOneNorm")
end

# Require the user to press a button before the figures are closed
# commSize = El.mpi.Size( El.mpi.COMM_WORLD() )
El.Finalize()
# if commSize == 1:
#   raw_input('Press Enter to exit')
