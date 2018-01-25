type Grid
	obj::Ptr{Void}
end

# destructor to be used in finalizer. Don't call explicitly
function destroy(G::Grid)
    ElError(ccall(("ElGridDestroy", libEl), Cuint,
        (Ptr{Void},), G.obj))
    return nothing
end

# Returns the default Grid. The default grid is finalized when Elemental is finalized
# so we shouldn't register a `destroy` as finalizer.
function Grid()
    obj = Ref{Ptr{Void}}(C_NULL)
        ElError(ccall(("ElDefaultGrid", libEl), Cuint,
            (Ref{Ptr{Void}},), obj))
    return Grid(obj[])
end

const DefaultGrid = Ref{Grid}()
