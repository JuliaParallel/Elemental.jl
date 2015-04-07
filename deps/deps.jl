macro checked_lib(lib)
    libname = join((lib, Libdl.dlext), ".")
    path = abspath(joinpath(dirname(@__FILE__), "usr", "lib", libname))
    if Libdl.dlopen_e(path) == C_NULL
        error("Unable to load $libname\n($path)\nPlease re-run Pkg.build(\"Elemental\"), and restart Julia.")
    end
    return quote
        const $(esc(lib)) = $path
    end
end
@checked_lib libEl
