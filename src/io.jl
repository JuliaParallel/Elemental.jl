for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))

    @eval begin
        function print(A::DistMatrix{$elty}, title::String)
            err = ccall(($(string("ElPrintDist_", ext)), libEl), Cuint,
                (Ptr{Void}, Ptr{UInt8}),
                A.obj, title)
            err == 0 || throw(ElError(err))
        end
    end
end