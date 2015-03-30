using BinDeps

ELEMENTAL_VERSION = "0.86-rc1"

@BinDeps.setup

libEl = library_dependency("libEl")

provides(Sources,
         URI("https://github.com/elemental/Elemental/archive/$ELEMENTAL_VERSION.tar.gz"),
         libEl,
         unpacked_dir="Elemental-$ELEMENTAL_VERSION")

srcdir = joinpath(BinDeps.depsdir(libEl), "src", "Elemental-$ELEMENTAL_VERSION")

provides(SimpleBuild,
    (@build_steps begin
        GetSources(libEl)
        @build_steps begin
            ChangeDirectory(srcdir)
        end
    end),
    libEl, os=:Unix
)

@BinDeps.install Dict(:libEl => :libEl)
