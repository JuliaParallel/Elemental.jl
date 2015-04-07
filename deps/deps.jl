macro checked_lib(lib)
    libname = join((lib, Libdl.dlext), ".")
    libdir = abspath(joinpath(dirname(@__FILE__), "usr", "lib"))
    libpath = Libdl.find_library([string(lib),], [libdir])
    if isempty(libpath)
        error("Unable to load $libname\n($libpath)\nPlease re-run Pkg.build(\"Elemental\"), and restart Julia.")
    end
    return quote
        const $(esc(lib)) = $libpath
    end
end
@checked_lib libEl
