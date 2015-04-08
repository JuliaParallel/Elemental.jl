for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d), 
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))
    for (mat, sym) in ((:Matrix, "_"),
                       (:DistMatrix, "Dist_"))
        @eval begin
        	function A_mul_B!(α::$elty, A::$mat{$elty}, x::$mat{$elty}, β::$elty, y::$mat{$elty})
            	err = ccall(($(string("ElGemv", sym, ext)), libEl), Cuint,
                	(Cint, $elty, Ptr{Void}, Ptr{Void}, $elty, Ptr{Void}),
                	EL_NORMAL, α, A.obj, x.obj, β, y.obj)
            	err == 0 || error("something is wrong here!")
            	return y
            end
        end
    end
end