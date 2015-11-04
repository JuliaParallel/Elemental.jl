type DistMultiVec{T} <: ElementalMatrix{T}
    obj::Ptr{Void}
end

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function DistMultiVec(::Type{$elty}, cm::ElComm = CommWorld)
            obj = Ref{Ptr{Void}}(C_NULL)
            err = ccall(($(string("ElDistMultiVecCreate_", ext)), libEl), Cuint,
                (Ref{Ptr{Void}}, ElComm),
                obj, cm)
            err == 0 || throw(ElError(err))
            return DistMultiVec{$elty}(obj[])
        end

        function comm(A::DistMultiVec{$elty})
            cm = Ref{ElComm}()
            err = ccall(($(string("ElDistMultiVecComm_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElComm}),
                A.obj, cm)
            err == 0 || throw(ElError(err))
            return cm[]
        end

        function get(x::DistMultiVec{$elty}, i::Integer = size(x, 1), j::Integer = 1)
            v = Ref{$elty}()
            err = ccall(($(string("ElDistMultiVecGet_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, Ref{$elty}),
                x.obj, i - 1, j - 1, v)
            err == 0 || throw(ElError(err))
            return v[]
        end

        function height(x::DistMultiVec{$elty})
            i = Ref{ElInt}()
            err = ccall(($(string("ElDistMultiVecHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                x.obj, i)
            err == 0 || throw(ElError(err))
            return i[]
        end

        function processQueues(A::DistMultiVec{$elty})
            err = ccall(($(string("ElDistMultiVecProcessQueues_", ext)), libEl), Cuint,
                (Ptr{Void},), A.obj)
            err == 0 || throw(ElError(err))
          return nothing
        end

        function queueUpdate(A::DistMultiVec{$elty}, i::Integer, j::Integer, value::$elty)
            err = ccall(($(string("ElDistMultiVecQueueUpdate_", ext)), libEl), Cuint,
              (Ptr{Void}, ElInt, ElInt, $elty),
              A.obj, i - 1, j - 1, value)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function reserve(A::DistMultiVec{$elty}, numEntries::Integer)
            err = ccall(($(string("ElDistMultiVecReserve_", ext)), libEl), Cuint,
              (Ptr{Void}, ElInt),
              A.obj, numEntries)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function resize!(A::DistMultiVec{$elty}, m::Integer, n::Integer = 1) # to mimic vector behavior
            err = ccall(($(string("ElDistMultiVecResize_", ext)), libEl), Cuint,
              (Ptr{Void}, ElInt, ElInt),
              A.obj, ElInt(m), ElInt(n))
            err == 0 || throw(ElError(err))
            return A
        end

        function width(x::DistMultiVec{$elty})
            i = Ref{ElInt}()
            err = ccall(($(string("ElDistMultiVecWidth_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                x.obj, i)
            err == 0 || throw(ElError(err))
            return i[]
        end
    end
end

#########################
### Julia convenience ###
#########################

getindex(x::DistMultiVec, i, j) = get(x, i, j)

function similar{T}(::DistMultiVec, ::Type{T}, sz::Dims, cm::ElComm = CommWorld)
    A = DistMultiVec(T, cm)
    resize!(A, sz...)
    return A
end
