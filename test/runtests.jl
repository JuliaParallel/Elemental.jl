using Test

function runtests_mpirun()
    nprocs = min(4, Sys.CPU_THREADS)
    testdir = dirname(@__FILE__)
    testfiles = ["lav.jl", "lavdense.jl", "matrix.jl", "distmatrix.jl", "props.jl", "generic.jl", "spectral.jl"]
    nfail = 0
    @info "Running Elemental.jl tests"
    for f in testfiles
        try
            run(`mpirun -np $nprocs $(Base.julia_cmd()) $(joinpath(testdir, f))`)
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
    testdir = dirname(@__FILE__)
    testfiles = ["darray.jl"]
    nfail = 0
    @info "Running Elemental.jl tests"
    for f in testfiles
        try
            # FixMe! We temporarily run Finalize() explictly on the workers because the atexit hook
            # doesn't seem to be correctly triggered on workers as of 31 October 2018.
            cmdstr = "using Distributed, MPI; man = MPIManager(np = $nprocs); addprocs(man); include(\"$(joinpath(testdir, f))\"); asyncmap(p -> remotecall_fetch(() -> Elemental.Finalize(), p), workers())"
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
    return runtests_mpirun() & runtests_repl()
end

exit(runtests())
