# Detect Elemental integer size
function ElIntType()
    using64 = Cint[0]
    err = ccall((:ElUsing64BitInt, libEl), Cuint, (Ptr{Cint},), using64)
    err == 0 || error("something is wrong here!")
    return using64[1] == 1 ? Int64 : Int32
end
const ElInt = ElIntType()

# Detect Elemental Bool type
function ElBoolType()
    boolsize = Ref(zero(Cuint))
    err = ccall((:ElSizeOfBool, libEl), Cint, (Ref{Cuint},), boolsize)
    err == 0 || error("something is wrong here!")
    return boolsize[] == 1 ? Uint8 : Uint32
end
const ElBool = ElBoolType()

typealias ElFloatType Union(Float64,Float32)

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
