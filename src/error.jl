immutable ElError <: Exception
end

immutable ElRuntimeError <: Exception
end

immutable ElLogicError <: Exception
end

immutable ElArgumentError <: Exception
end

immutable ElBoundsError <: Exception
end

immutable ElAllocError <: Exception
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
        return ElError()
    else
        throw(ArgumentError("Unknown Elemental Error Code: $code"))
    end
end

ErrorString(code::Integer) =
    btyestring(ccall((:ElErrorString, libEl), Ptr{Cchar}, (Cint,), code))
