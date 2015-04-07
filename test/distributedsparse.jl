using Elemental

using MPI

n0 = 50
n1 = 50
display = true
worldRank = MPI.Comm_rank(MPI.COMM_WORLD)

function stackedFD2D(n0, n1)
    height = 2*n0*n1
    width = n0*n1
    A = Elemental.DistSparseMatrix(Float64, height, width)
    localHeight = Elemental.localHeight(A)
    Elemental.reserve(A, 6*localHeight)
    for sLoc in 0:localHeight - 1
        s = Elemental.globalRow(A, sLoc)
        if s < n0*n1
            x0 = s % n0
            x1 = div(s, n0)
            Elemental.queueLocalUpdate(A, sLoc, s, 11.0)
            if x0 > 0
                Elemental.queueLocalUpdate(A, sLoc, s - 1, -10.0)
            end
            if x0 + 1 < n0
                Elemental.queueLocalUpdate(A, sLoc, s + 1, 20.0)
            end
            if x1 > 0
                Elemental.queueLocalUpdate(A, sLoc, s - n0, -30.0)
            end
            if x1 + 1 < n1
                Elemental.queueLocalUpdate(A, sLoc, s + n0, 40.0)
            end
        else
            sRel = s - n0*n1
            x0 = sRel % n0
            x1 = div(sRel, n0)
            Elemental.queueLocalUpdate(A, sLoc, sRel, -20.0)
            if x0 > 0
                Elemental.queueLocalUpdate(A, sLoc, sRel - 1, -1.0)
            end
            if x0 + 1 < n0
                Elemental.queueLocalUpdate(A, sLoc, sRel + 1, -2.0)
            end
            if x1 > 0
                Elemental.queueLocalUpdate(A, sLoc, sRel - n0, -3.0)
            end
            if x1 + 1 < n1
                Elemental.queueLocalUpdate(A, sLoc, sRel + n0, 3.0)
            end
        end

        # The dense last column
        Elemental.queueLocalUpdate(A, sLoc, width - 1, -div(10.0, height))

        Elemental.makeConsistent(A)
    end
    return A
end

A = stackedFD2D(n0, n1)
@show size(A)
b = Elemental.DistMultiVec(Float64)
Elemental.gaussian(b, 2*n0*n1, 1)

@show bTwoNorm = Elemental.nrm2(b)

# if display
    # show(IO, A)
# end
ctrl = Elemental.LPAffineCtrl(Float64)
unsafe_store!(convert(Ptr{Cint}, pointer_from_objref(ctrl.mehrotraCtrl.qsdCtrl.progress)), true, 1)
unsafe_store!(convert(Ptr{Cint}, pointer_from_objref(ctrl.mehrotraCtrl.progress)), true, 1)
unsafe_store!(convert(Ptr{Cint}, pointer_from_objref(ctrl.mehrotraCtrl.outerEquil)), true, 1)
unsafe_store!(convert(Ptr{Cint}, pointer_from_objref(ctrl.mehrotraCtrl.time)), true, 1)
# ctrl.mehrotraCtrl.progress = true
# ctrl.mehrotraCtrl.outerEquil = true
# ctrl.mehrotraCtrl.time = true
gc()
@show Elemental.comm(A)
x = Elemental.lav(A, b)
# x = Elemental.lav(A, b, ctrl)


@show Elemental.destroy(A)