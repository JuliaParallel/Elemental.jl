using Test
using Elemental_jll.MPICH_jll: mpiexec

# Import all of our external dependencies to make sure they're compiled serially.
using DistributedArrays
using TSVD
using Primes
using MPIClusterManagers
using Elemental

function runtests_mpirun()
    nprocs = min(4, Sys.CPU_THREADS)
    testfiles = ["lav.jl", "lavdense.jl", "matrix.jl", "distmatrix.jl", "props.jl", "generic.jl", "spectral.jl", "tsvd.jl", "svd.jl"]
    nfail = 0
    @info "Running Elemental.jl tests"
    for f in testfiles
        try
            mpiexec() do exec
                run(`$exec -np $nprocs $(Base.julia_cmd()) $(joinpath(@__DIR__, f))`)
            end
            Base.with_output_color(:green,stdout) do io
                println(io,"\tSUCCESS: $f")
            end
        catch ex
            Base.with_output_color(:red,stderr) do io
                println(io,"\tError: $f")
                showerror(io,ex,backtrace())
            end
            nfail += 1
        end
    end
    return nfail
end

function runtests_repl()
    nprocs = min(4, Sys.CPU_THREADS)
    exename = joinpath(Sys.BINDIR, Base.julia_exename())
    testfiles = ["darray.jl"]
    nfail = 0
    @info "Running Elemental.jl tests"
    for f in testfiles
        try
            # FixMe! We temporarily run Finalize() explictly on the workers because the atexit hook
            # doesn't seem to be correctly triggered on workers as of 31 October 2018.
            cmdstr = "using Distributed, MPIClusterManagers; man = MPIManager(np = $nprocs); addprocs(man); include(\"$(joinpath(@__DIR__, f))\"); asyncmap(p -> remotecall_fetch(() -> Elemental.Finalize(), p), workers())"
            run(`$exename -e $cmdstr`)
            Base.with_output_color(:green,stdout) do io
                println(io,"\tSUCCESS: $f")
            end
        catch ex
            Base.with_output_color(:red,stderr) do io
                println(io,"\tError: $f")
                showerror(io,ex,backtrace())
            end
            nfail += 1
        end
    end
    return nfail
end

function runtests()
    return runtests_mpirun() + runtests_repl()
end

exit(runtests())
