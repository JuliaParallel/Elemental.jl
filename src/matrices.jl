for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))
    @eval begin
        function gaussian(A::DistMultiVec{$elty}, m::Integer, n::Integer, mean::$elty = zero($elty), stddev::$relty = one($relty))
            err = ccall(($(string("ElGaussianDistMultiVec_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, $elty, $relty),
                A.obj, m, n, mean, stddev)
            err == 0 || error("something is wrong here!")
            return nothing
        end
    end
end