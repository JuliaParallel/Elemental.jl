@enum FileFormat AUTO ASCII ASCII_MATLAB BINARY BINARY_FLAT BMP JPG JPEG MATRIX_MARKET PNG PPM XBM XPM FileFormat_MAX

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:ComplexF32, :c),
                    (:ComplexF64, :z))
    for mattype in ("", "Dist", "Sparse", "DistSparse")
        mat = Symbol(mattype, "Matrix")
        @eval begin
            function print(A::$mat{$elty}, title::String)
                ElError(ccall(($(string("ElPrint", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{UInt8}),
                    A.obj, title))
            end

            function write(A::$mat{$elty}, basename::String, format::FileFormat, title::String)
                ElError(ccall(($(string("ElWrite", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{UInt8}, FileFormat, Ptr{UInt8}),
                    A.obj, basename, format, title))
            end
        end
    end
end