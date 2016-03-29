type Grid
	obj::Ptr{Void}
end

function Grid()
    obj = Ref{Ptr{Void}}(C_NULL)
        err = ccall(("ElDefaultGrid", libEl), Cuint,
            (Ref{Ptr{Void}},), obj)
    err == 0 || throw(ElError(err))
    return Grid(obj[])
end
