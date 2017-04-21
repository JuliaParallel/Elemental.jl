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
    # NOTE: Returning Uint8 when C claims that sizeof(bool) is 1 byte leads
    #       to improperly passed structs to Elemental's C interface. This is
    #       worth investigating and might be an alignment issue.

    # warn("Hardcoding ElBool to Cint")
    boolsize = Ref(zero(Cuint))
    err = ccall((:ElSizeOfCBool, libEl), Cuint, (Ref{Cuint},), boolsize)
    err == 0 || throw(ElError(err))
    return boolsize[] == 1 ? UInt8 : Cint
end
const ElBool = ElBoolType()

function ElBool(value::Bool)
    if value
      return ElBool(1)
    else
      return ElBool(0)
    end
end

using Base.LinAlg: BlasFloat, BlasReal, BlasComplex

const ElElementType = Union{ElInt,Float32,Float64,Complex64,Complex128}

const ElFloatType   = Union{Float32,Float64} # TODO: Maybe just use BlasReal here

@compat abstract type ElementalMatrix{T} <: AbstractMatrix{T} end
eltype{T}(A::ElementalMatrix{T}) = T

# Error is handled in error.jl as an Exception

@enum SortType UNSORTED DESCENDING ASCENDING
@enum Dist MC MD MR VC VR STAR CIRC
@enum Orientation NORMAL TRANSPOSE ADJOINT
@enum UpperOrLower LOWER UPPER

# Get MPIWorldComm
function CommWorldValue()
    r = Ref{ElComm}(0)
    ccall((:ElMPICommWorld, libEl), Cuint, (Ref{ElComm},), r)
    return r[]
end
const CommWorld = CommWorldValue()
