for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))
    @eval begin
        function nrm2(x::DistMultiVec{$elty})
            nm = Ref{$relty}(0)
            err = ccall(($(string("ElNrm2DistMultiVec_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{$relty}),
                x.obj, nm)
            err == 0 || error("something is wrong here!")
            return nm[]
        end

        function copy!(src::DistMultiVec{$elty}, dest::DistMultiVec{$elty})
            err = ccall(($(string("ElCopyDistMultiVec_", ext)), libEl), Cuint,
                (Ptr{Void}, Ptr{Void}),
                src.obj, dest.obj)
            err == 0 || error("something is wrong here!")
            dest
        end
    end
end
copy(A::DistMultiVec) = copy!(A, similar(A))