type DistMultiVec{T} <: ElementalMatrix{T}
    obj::Ptr{Void}
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function DistMultiVec(::Type{$elty}, comm = MPI.COMM_WORLD)
            obj = Ref{Ptr{Void}}(C_NULL)
            err = ccall(($(string("ElDistMultiVecCreate_", ext)), libEl), Cuint,
                (Ref{Ptr{Void}}, Cint),
                obj, comm.val)
            err == 0 || throw(ElError(err))
            return DistMultiVec{$elty}(obj[])
        end

        # function DistMultiVec(::Type{$elty}, m::Integer, n::Integer, comm = MPI.COMM_WORLD)
        #     obj = Ref{Ptr{Void}}(C_NULL)
        #     err = ccall(($(string("ElDistMultiVecCreate_", ext)), libEl), Cuint,
        #         (Ref{Ptr{Void}}, Cint),
        #         obj, comm.val)
        #     return DistMultiVec{$elty}(obj[])
        # end
        function height(x::DistMultiVec{$elty})
            i = Ref{ElInt}(zero($elty))
            err = ccall(($(string("ElDistMultiVecHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{Cint}),
                x.obj, i)
            err == 0 || throw(ElError(err))
            return i[]
        end


    end
end

eltype{T}(x::DistMultiVec{T}) = T
size(x::DistMultiVec) = (Int(height(x)),)
similar{T}(x::DistMultiVec{T}, cm = MPI.COMM_WORLD) = DistMultiVec(T, cm)
