for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))

    @eval begin
        function print(A::DistMatrix{$elty}, title::String)
            ElError(ccall(($(string("ElPrintDist_", ext)), libEl), Cuint,
                (Ptr{Void}, Ptr{UInt8}),
                A.obj, title))
        end
    end
end