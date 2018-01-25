struct AllocError    <: Exception end
struct BoundsError   <: Exception end
struct Error         <: Exception end
struct RuntimeError  <: Exception end
struct LogicError    <: Exception end
struct ArgumentError <: Exception end

function ElError(code::Integer)
    if code == 0
        return nothing
    elseif code == 1
        throw(AllocError())
    elseif code == 2
        throw(BoundsError())
    elseif code == 3
        throw(ArgumentError())
    elseif code == 4
        throw(LogicError())
    elseif code == 5
        throw(RuntimeError())
    elseif code == -1
        # catchall error code
        return throw(Error())
    else
        throw(ArgumentError("Unknown Elemental Error Code: $code"))
    end
end

ErrorString(code::Integer) =
    String(ccall((:ElErrorString, libEl), Ptr{Cchar}, (Cint,), code))
