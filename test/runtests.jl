using Elemental
using Base.Test

function runtests_mpirun()
    nprocs = min(4, Sys.CPU_CORES)
    exename = joinpath(JULIA_HOME, Base.julia_exename())
    testdir = dirname(@__FILE__)
    testfiles = ["lav.jl", "lavdense.jl", "matrix.jl", "distmatrix.jl", "props.jl", "generic.jl"]
    nfail = 0
    print_with_color(:white, "Running Elemental.jl tests\n")
    for f in testfiles
        try
            run(`mpirun -np $nprocs $exename $(joinpath(testdir, f))`)
            Base.with_output_color(:green,STDOUT) do io
                println(io,"\tSUCCESS: $f")
            end
        catch ex
            Base.with_output_color(:red,STDERR) do io
                println(io,"\tError: $f")
                showerror(io,ex,backtrace())
            end
            nfail += 1
        end
    end
    return nfail
end

function runtests_repl()
    nprocs = min(4, Sys.CPU_CORES)
    exename = joinpath(JULIA_HOME, Base.julia_exename())
    testdir = dirname(@__FILE__)
    testfiles = ["darray.jl"]
    nfail = 0
    print_with_color(:white, "Running Elemental.jl tests\n")
    for f in testfiles
        try
            cmdstr = "using MPI; man = MPIManager(np = $nprocs); addprocs(man); include(\"$(joinpath(testdir, f))\")"
            run(`$exename -e $cmdstr`)
            Base.with_output_color(:green,STDOUT) do io
                println(io,"\tSUCCESS: $f")
            end
        catch ex
            Base.with_output_color(:red,STDERR) do io
                println(io,"\tError: $f")
                showerror(io,ex,backtrace())
            end
            nfail += 1
        end
    end
    return nfail
end

function runtests()
    return runtests_mpirun() #+ runtests_repl() 2 August 2016. comment out until DistributedArrays has been tagged
end

exit(runtests())
