mutable struct Grid
	obj::Ptr{Cvoid}
end

# destructor to be used in finalizer. Don't call explicitly
function destroy(G::Grid)
    ElError(ccall(("ElGridDestroy", libEl), Cuint,
        (Ptr{Cvoid},), G.obj))
    return nothing
end

# Returns the default Grid. The default grid is finalized when Elemental is finalized
# so we shouldn't register a `destroy` as finalizer.
function Grid()
    obj = Ref{Ptr{Cvoid}}(C_NULL)
        ElError(ccall(("ElDefaultGrid", libEl), Cuint,
            (Ref{Ptr{Cvoid}},), obj))
    return Grid(obj[])
end

const DefaultGrid = Ref{Grid}()
