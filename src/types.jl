# Detect Elemental integer size
function ElIntType()
    using64 = Cint[0]
    err = ccall((:ElUsing64BitInt, libEl), Cuint, (Ptr{Cint},), using64)
    err == 0 || throw(ElError(err))
    return using64[1] == 1 ? Int64 : Int32
end
const ElInt = ElIntType()

function ElCommType()
    sameSizeAsInt = Cint[0]
    err = ccall((:ElMPICommSameSizeAsInteger, libEl), Cuint, (Ptr{Cint},), 
      sameSizeAsInt)
    err == 0 || throw(ElError(err))
    return sameSizeAsInt[1] == 1 ? Cint : Ptr{Void}
end
const ElComm = ElCommType()

function ElGroupType()
    sameSizeAsInt = Cint[0]
    err = ccall((:ElMPIGroupSameSizeAsInteger, libEl), Cuint, (Ptr{Cint},), 
      sameSizeAsInt)
    err == 0 || throw(ElError(err))
    return sameSizeAsInt[1] == 1 ? Cint : Ptr{Void}
end
const ElGroup = ElGroupType()

# Detect Elemental Bool type
function ElBoolType()
    boolsize = Ref(zero(Cuint))
    err = ccall((:ElSizeOfCBool, libEl), Cint, (Ref{Cuint},), boolsize)
    err == 0 || throw(ElError(err))
    return boolsize[] == 1 ? Uint8 : Uint32
end
const ElBool = ElBoolType()

function ElBool(value::Bool)
    if value
      return ElBool(1)
    else
      return ElBool(0)
    end
end

typealias ElFloatType Union(Float32,Float64)

abstract ElementalMatrix{T} <: AbstractMatrix{T}

const EL_MC			= Cint(0)
const EL_MD			= Cint(1)
const EL_MR			= Cint(2)
const EL_VC			= Cint(3)
const EL_VR			= Cint(4)
const EL_STAR		= Cint(5)
const EL_CIRC		= Cint(6)

const EL_NORMAL 	= Cint(0)
const EL_TRANSPOSE 	= Cint(1)
const EL_ADJOINT 	= Cint(2)
