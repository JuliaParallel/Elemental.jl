import Elemental
const El = Elemental
using LinearAlgebra: mul!

n0 = 50
n1 = 50
testNative = true
display = false
worldRank = El.MPI.commRank(El.MPI.CommWorld[])
worldSize = El.MPI.commSize(El.MPI.CommWorld[])
if worldRank == 0
  print("worldSize=$worldSize\n")
end

using DistributedArrays

function randDArray(m,n,sparsity=0.01)
    DA = DistributedArrays.DArray((m,n)) do I
        sprandn(length(I[1]), length(I[2]), sparsity)
    end
    A = El.DistSparseMatrix{Float64}(DA)
    return A
end

# Stack two 2D finite-difference matrices on top of each other
# and make the last column dense
function stackedFD2D(n0, n1)
    height = 2*n0*n1
    width = n0*n1
    A = El.DistSparseMatrix(Float64, height, width)
    localHeight = El.localHeight(A)
    El.reserve(A, 6*localHeight)

    for sLoc in 1:localHeight
        s = El.globalRow(A, sLoc)
        if s <= n0*n1
            x0 = ((s-1) % n0) + 1
            x1 = div((s-1), n0) + 1
            El.queueUpdate(A, s, s, 11.0)
            if x0 > 1
                El.queueUpdate(A, s, s - 1, -10.0)
            end
            if x0 < n0
                El.queueUpdate(A, s, s + 1, 20.0)
            end
            if x1 > 1
                El.queueUpdate(A, s, s - n0, -30.0)
            end
            if x1 < n1
                El.queueUpdate(A, s, s + n0, 40.0)
            end
        else
            sRel = s - n0*n1
            x0 = ((sRel-1) % n0) + 1
            x1 = div(sRel-1, n0) + 1
            El.queueUpdate(A, s, sRel, -20.0)
            if x0 > 1
                El.queueUpdate(A, s, sRel - 1, -1.0)
            end
            if x0 < n0
                El.queueUpdate(A, s, sRel + 1, -2.0)
            end
            if x1 > 1
                El.queueUpdate(A, s, sRel - n0, -3.0)
            end
            if x1 < n1
                El.queueUpdate(A, s, sRel + n0, 3.0)
            end
        end

        # The dense last column
        El.queueUpdate(A, s, width, floor(-10/height))
    end
    El.processQueues(A)
    return A
end

if testNative
    A = stackedFD2D(n0, n1)
else
    A = randDArray(2*n0*n1,n0*n1)
end

b = El.DistMultiVec(Float64)
El.gaussian!(b, 2*n0*n1, 1)

AHeight = El.height(A)
AWidth = El.width(A)
bHeight = El.height(b)
bWidth = El.width(b)

if display
    El.print(A, "A")
    # El.print(b, "b")
end

ctrl = El.LPAffineCtrl(Float64,
    mehrotraCtrl=El.MehrotraCtrl(Float64,
        solveCtrl=El.RegSolveCtrl(Float64,
                                  progress=true),
        print=true,
        outerEquil=true,
        time=true)
    )

# elapsedLAV = @elapsed x = El.lav(A, b);#Elemental.print(A, "Matrix A")
elapsedLAV = @elapsed x = El.lav(A, b, ctrl)

if El.MPI.commRank(El.MPI.CommWorld[]) == 0
    println("LAV time: $elapsedLAV seconds")
end
bTwoNorm = El.nrm2(b)
bInfNorm = El.maxNorm(b)

r = copy(b)
mul!(r, A, x, -1.0, 1.0)

rTwoNorm = El.nrm2(r)
rOneNorm = El.entrywiseNorm(r, 1)

if El.MPI.commRank(El.MPI.CommWorld[]) == 0
    println("|| b ||_2       = $bTwoNorm")
    println("|| b ||_oo      = $bInfNorm")
    println("|| A x - b ||_2 = $rTwoNorm")
    println("|| A x - b ||_1 = $rOneNorm")
end

elapsedLS = @elapsed xLS = El.leastSquares(A, b)

if El.MPI.commRank(El.MPI.CommWorld[]) == 0
    println("LS time: $elapsedLAV seconds")
end

rLS = copy(b)
mul!(rLS, A, xLS, -1.0, 1.0)
if display
    El.print( rLS, "A x_{LS} - b" )
end

rLSTwoNorm = El.nrm2(rLS)
rLSOneNorm = El.entrywiseNorm(rLS, 1)
if El.MPI.commRank(El.MPI.CommWorld[]) == 0
    println("|| A x_{LS} - b ||_2 = $rLSTwoNorm")
    println("|| A x_{LS} - b ||_1 = $rLSOneNorm")
end

# Require the user to press a button before the figures are closed
# commSize = El.mpi.Size( El.mpi.COMM_WORLD() )
# El.Finalize()
