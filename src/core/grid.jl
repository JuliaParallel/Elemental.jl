using CEnum

@cenum ElGridOrderType::UInt32 begin
    EL_ROW_MAJOR = 0
    EL_COLUMN_MAJOR = 1
end

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
function DefaultGrid()
    obj = Ref{Ptr{Cvoid}}(C_NULL)
        ElError(ccall(("ElDefaultGrid", libEl), Cuint,
            (Ref{Ptr{Cvoid}},), obj))
    return Grid(obj[])
end

# Returns the trivial Grid. The default grid is finalized when Elemental is finalized
# so we shouldn't register a `destroy` as finalizer.
function TrivialGrid()
    obj = Ref{Ptr{Cvoid}}(C_NULL)
        ElError(ccall(("ElTrivialGrid", libEl), Cuint,
            (Ref{Ptr{Cvoid}},), obj))
    return Grid(obj[])
end

function row(G::Grid)
    row = Ref{Cint}()
    ElError(ccall(("ElGridRow", libEl), Cuint,
        (Ptr{Cvoid}, Ptr{Cint}), G.obj, row))
    return row[]
end

function column(G::Grid)
    col = Ref{Cint}()
    ElError(ccall(("ElGridCol", libEl), Cuint,
        (Ptr{Cvoid}, Ptr{Cint}), G.obj, col))
    return col[]
end

