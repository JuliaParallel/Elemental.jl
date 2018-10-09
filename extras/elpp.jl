module Elpp

# Cxx stuff
using Cxx

const ElInclude = joinpath(Pkg.dir(), "Elemental/deps/usr/include/")

addHeaderDir(ElInclude, kind=C_System)
addHeaderDir("/usr/local/include/", kind=C_System)

# Libdl.dlopen(ElInclude * "../lib/libpmrrr", Libdl.RTLD_GLOBAL)
# Libdl.dlopen(ElInclude * "../lib/libElSuiteSparse", Libdl.RTLD_GLOBAL)
# Libdl.dlopen(ElInclude * "../lib/libmetis", Libdl.RTLD_GLOBAL)
# Libdl.dlopen(ElInclude * "../lib/libparmetis", Libdl.RTLD_GLOBAL)
Libdl.dlopen(ElInclude * "../lib/libEl", Libdl.RTLD_GLOBAL)

cxxinclude("El.hpp")

# Julia setup
import Base: convert, copy!, getindex, randn!, setindex!, similar, size, svdvals, svdvals!

const ElInt = icxx"sizeof(El::Int);" == 4 ? Int32 : Int64

_initialize(argc, argv) = icxx"El::Initialize($argc, $argv);"
initialize() = _initialize(Cint(0), convert(Ptr{Ptr{Cuchar}}, C_NULL))

finalize() = icxx"El::Finalize();"

### ElementalMatrix ###
# Many of the definitions in Elemental are very similar which makes it easy to define methods for a common abstract type. However, we should be careful when calling into the library with e.g. @cxx or icxx because all leaf types might not implement the actual method.

abstract type ElementalMatrix{T} <: AbstractMatrix{T} end

_getindex(A::ElementalMatrix, i::ElInt, j::ElInt) = icxx"$(A.buf).Get($i, $j);"
getindex(A::ElementalMatrix, i::Integer, j::Integer) = _getindex(A, ElInt(i - 1), ElInt(j - 1))

function size(A::ElementalMatrix, i::ElInt)
    if i < 1
        throw(error(""))
    elseif i == 1
        return Int(icxx"$(A.buf).Height();")
    elseif i == 2
        return Int(icxx"$(A.buf).Width();")
    else
        return 1
    end
end
size(A::ElementalMatrix) = (size(A, 1), size(A, 2))

similar(A::ElementalMatrix) = typeof(A)(size(A)...)
similar(A::ElementalMatrix, sz::Tuple{Int,Int}) = typeof(A)(ElInt(sz[1]), ElInt(sz[2]))

function copy!{T<:ElementalMatrix}(dest::T, src::T)
    @cxx El::Copy(src.buf, dest.buf)
    return dest
end

function randn!(A::ElementalMatrix)
    _randn!(A, size(A)...)
    return A
end

svdvals(A::ElementalMatrix) = svdvals!(copy(A))

### AbstractDistMatrix ###
abstract type AbstractDistMatrix{T} <: ElementalMatrix{T} end

_resize!(A::AbstractDistMatrix, i::ElInt, j::ElInt) = icxx"$(A.buf).Resize($i, $j);"
resize!(A::AbstractDistMatrix, i::Integer, j::Integer) = _resize!(A, ElInt(i), ElInt(j))

_reserve(A::AbstractDistMatrix, n::ElInt) = icxx"$(A.buf).Reserve($n);"
reserve(A::AbstractDistMatrix, n::Integer) = _reserve(A, ElInt(n))

_queueUpdate(A::AbstractDistMatrix{T}, i::ElInt, j::ElInt, x::T) where {T} = icxx"$(A.buf).QueueUpdate($i, $j, $x);"
queueUpdate(A::AbstractDistMatrix{T}, i::Integer, j::Integer, x) where {T} = _queueUpdate(A, ElInt(i - 1), ElInt(j - 1), T(x))

processQueues!(A::AbstractDistMatrix) = icxx"$(A.buf).ProcessQueues();"

_zeros!(A::AbstractDistMatrix, m::ElInt, n::ElInt) = icxx"El::Zeros($(A.buf), $m, $n);"
zeros!(A::AbstractDistMatrix, m::Integer = size(A,1), n::Integer = size(A,2)) = _zeros!(A, ElInt(m), ElInt(n))

### Matrix ###

struct Matrix{T} <: ElementalMatrix{T}
    # buf::Cxx.CppValue{Cxx.CxxQualType{Cxx.CppTemplate{Cxx.CppBaseType{symbol("El::Matrix")},Tuple{T}},(false,false,false)},56}
    buf::Any
end

convert(::Type{Matrix{Float32}}, m::ElInt = 0, n::ElInt = 0) = Matrix{Float32}(icxx"El::Matrix<float>($m,$n);")
convert(::Type{Matrix{Float64}}, m::ElInt = 0, n::ElInt = 0) = Matrix{Float64}(icxx"El::Matrix<double>($m,$n);")

_randn!(A::Matrix, i::ElInt, j::ElInt) = icxx"Gaussian($(A.buf), $i, $j);"

function LinearAlgebra.svdvals!(A::Matrix{T}) where {T}
    s = Matrix{T}(min(size(A)...),1)
    @cxx El::SVD(A.buf, s.buf)
    return s
end

# immutable Grid

# DistMatrix

struct DistMatrix{T,U,V} <: AbstractDistMatrix{T}
    # buf::Cxx.CppValue{Cxx.CxxQualType{Cxx.CppTemplate{Cxx.CppBaseType{symbol("El::DistMatrix")},Tuple{T,U,V,U}},(false,false,false)},144}
    buf::Any
end

const MC = Cxx.CppEnum{symbol("El::DistNS::Dist")}(0)
const MR = Cxx.CppEnum{symbol("El::DistNS::Dist")}(2)

# These converstions for C++ enums are necessary
convert(::Type{Cxx.CppEnum{symbol("El::DistNS::Dist")}}, x::Int) = Cxx.CppEnum{symbol("El::DistNS::Dist")}(x)
convert(::Type{Cxx.CppEnum{symbol("El::DistWrapNS::DistWrap")}}, x::Int) = Cxx.CppEnum{symbol("El::DistWrapNS::DistWrap")}(x)

convert(::Type{DistMatrix{Float32,MC,MR}}, m::ElInt = 0, n::ElInt = 0) = DistMatrix{Float32,MC,MR}(icxx"El::DistMatrix<float,El::MC,El::MR>($m,$n);")
convert(::Type{DistMatrix{Float64,MC,MR}}, m::ElInt = 0, n::ElInt = 0) = DistMatrix{Float64,MC,MR}(icxx"El::DistMatrix<double,El::MC,El::MR>($m,$n);")
convert(::Type{DistMatrix{T}}, m::ElInt = 0, n::ElInt = 0) where {T} = DistMatrix{T,MC,MR}(m, n)

_randn!(A::DistMatrix, i::ElInt, j::ElInt) = icxx"Gaussian($(A.buf), $i, $j);"

function LinearAlgebra.svdvals!(A::DistMatrix{T}) where {T}
    s = DistMatrix{T}(min(size(A)...),1)
    @cxx El::SVD(A.buf, s.buf)
    return s
end

# DistSparseMatrix
struct DistSparseMatrix{T} <: AbstractDistMatrix{T}
    buf::Any
end

convert(::Type{DistSparseMatrix{Float32}}, m::ElInt = 0, n::ElInt = 0) = DistSparseMatrix{Float32}(icxx"El::DistSparseMatrix<float>($m,$n);")
convert(::Type{DistSparseMatrix{Float64}}, m::ElInt = 0, n::ElInt = 0) = DistSparseMatrix{Float64}(icxx"El::DistSparseMatrix<double>($m,$n);")

processLocalQueues!(A::DistSparseMatrix) = icxx"$(A.buf).ProcessLocalQueues();"

# DistMultiVec
struct DistMultiVec{T} <: AbstractDistMatrix{T}
    buf::Any
end

convert(::Type{DistMultiVec{ElInt}}, m::ElInt = 0, n::ElInt = 0) = DistMultiVec{ElInt}(icxx"El::DistMultiVec<El::Int>($m,$n);")
convert(::Type{DistMultiVec{Float32}}, m::ElInt = 0, n::ElInt = 0) = DistMultiVec{Float32}(icxx"El::DistMultiVec<float>($m,$n);")
convert(::Type{DistMultiVec{Float64}}, m::ElInt = 0, n::ElInt = 0) = DistMultiVec{Float64}(icxx"El::DistMultiVec<double>($m,$n);")

_setindex!(A::DistMultiVec{T}, x::T, i::ElInt, j::ElInt) where {T} = icxx"$(A.buf).Set($i, $j, $x);"
setindex!(A::DistMultiVec{T}, x, i::Integer, j::Integer) where {T} = _setindex!(A, T(x), ElInt(i - 1), ElInt(j - 1))


### SOCP ###
socp(A::DistSparseMatrix, G::DistSparseMatrix, b::DistMultiVec, c::DistMultiVec, h::DistMultiVec, orders::DistMultiVec{ElInt}, firstInds::DistMultiVec{ElInt}, x::DistMultiVec, y::DistMultiVec, z::DistMultiVec, s::DistMultiVec) = icxx"El::SOCP($(A.buf), $(G.buf), $(b.buf), $(c.buf), $(h.buf), $(orders.buf), $(firstInds.buf), $(x.buf), $(y.buf), $(z.buf), $(s.buf));"

# DArray stuff

using DistributedArrays
function toback(A::DArray{Float64,2})
    rs = Array{Any}(size(A.chunks))
    for p in eachindex(A.chunks)
        ind = A.indexes[p]
        rs[p] = remotecall(A.pids[p], () -> begin
            lA = localpart(A)
            AlA = Elpp.DistMatrix{Float64}()
            Elpp.zeros!(AlA, size(A)...)
            for j = 1:size(lA, 2)
                for i = 1:size(lA, 1)
                    Elpp.queueUpdate(AlA, start(ind[1]) + i - 1, start(ind[2]) + j - 1, lA[i,j])
                end
            end
            Elpp.processQueues!(Main.AlA)
            AlA
        end)
    end
    rs
end

end

