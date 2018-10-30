# Detect Elemental integer size
function ElIntType()
    using64 = Cint[0]
    ElError(ccall((:ElUsing64BitInt, libEl), Cuint, (Ptr{Cint},), using64))
    return using64[1] == 1 ? Int64 : Int32
end
const ElInt = ElIntType()

function ElCommType()
    sameSizeAsInt = Cint[0]
    ElError(ccall((:ElMPICommSameSizeAsInteger, libEl), Cuint, (Ptr{Cint},),
      sameSizeAsInt))
    return sameSizeAsInt[1] == 1 ? Cint : Ptr{Cvoid}
end
const ElComm = ElCommType()

function ElGroupType()
    sameSizeAsInt = Cint[0]
    ElError(ccall((:ElMPIGroupSameSizeAsInteger, libEl), Cuint, (Ptr{Cint},),
      sameSizeAsInt))
    return sameSizeAsInt[1] == 1 ? Cint : Ptr{Cvoid}
end
const ElGroup = ElGroupType()

# Detect Elemental Bool type
function ElBoolType()
    # NOTE: Returning Uint8 when C claims that sizeof(bool) is 1 byte leads
    #       to improperly passed structs to Elemental's C interface. This is
    #       worth investigating and might be an alignment issue.

    # warn("Hardcoding ElBool to Cint")
    boolsize = Ref(zero(Cuint))
    ElError(ccall((:ElSizeOfCBool, libEl), Cuint, (Ref{Cuint},), boolsize))
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

using LinearAlgebra: BlasFloat, BlasReal, BlasComplex

const ElElementType = Union{ElInt,Float32,Float64,ComplexF32,ComplexF64}

const ElFloatType   = Union{Float32,Float64} # TODO: Maybe just use BlasReal here

abstract type ElementalMatrix{T} <: AbstractMatrix{T} end
eltype(A::ElementalMatrix{T}) where {T} = T

# Error is handled in error.jl as an Exception

@enum SortType UNSORTED DESCENDING ASCENDING
@enum Dist MC MD MR VC VR STAR CIRC
@enum Orientation NORMAL TRANSPOSE ADJOINT
@enum UpperOrLower LOWER UPPER
@enum LeftOrRight LEFT RIGHT
@enum UnitOrNonUnit NON_UNIT UNIT
@enum Pencil AXBX=1 ABX=2 BAX=3
