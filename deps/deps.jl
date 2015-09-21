# Since Julia recently changed its behavior so that it cannot automatically
# resolve shared libraries in the same directory as the library being loaded,
# this file now hackily attempts to optionally load libEl's dependencies
# before requiring that libEl loads
#
# NOTE: This behaviour was fixed by Jake Bolewski; the fix will be left
#       commented out in case of a future regression

macro checked_lib_opt(lib)
    libname = join((lib, Libdl.dlext), ".")
    libdir  = abspath(joinpath(dirname(@__FILE__), "usr", "lib"))
    libpath = joinpath(libdir, libname)
    if Libdl.dlopen_e(libpath) != C_NULL
      return quote
          const $(esc(lib)) = $libpath
      end
    end
end

macro checked_lib(lib)
    libname = join((lib, Libdl.dlext), ".")
    libdir  = abspath(joinpath(dirname(@__FILE__), "usr", "lib"))
    libpath = joinpath(libdir, libname)
    if Libdl.dlopen_e(libpath) == C_NULL
        error("Unable to load $libname\n($libpath)\nPlease re-run Pkg.build(\"Elemental\"), and restart Julia.")
    end
    return quote
        const $(esc(lib)) = $libpath
    end
end
@checked_lib_opt libmetis
@checked_lib_opt libparmetis
@checked_lib_opt libElSuiteSparse
@checked_lib_opt libpmrrr
@checked_lib libEl
