immutable ElError <: Exception
    msg::AbstractString
end

immutable ElRuntimeError <: Exception
    msg::AbstractString
end

immutable ElLogicError <: Exception
    msg::AbstractString
end

immutable ElArgumentError <: Exception
    msg::AbstractString
end

immutable ElBoundsError <: Exception
    msg::AbstractString
end

immutable ElAllocError <: Exception
    msg::AbstractString
end

function ElError(code::Integer)
    if code == 1
        return MemoryError()
    elseif code == 2
        return ArgumentError()
    elseif code == 3
        return ElLogicError()
    elseif code == 4
        return ElRuntimeError()
    elseif code == -1
        # catchall error code
        throw(ElError())
    else
        throw(ArgumentError("Unknown Elemental Error Code: $code"))
    end
end

ErrorString(code::Integer) =
    btyestring(ccall((:ElErrorString, libEl), Ptr{Cchar}, (Cint,), code))
