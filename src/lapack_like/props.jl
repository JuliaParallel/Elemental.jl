for (elty, relty, ext) in ((:Float32, :Float32, :s),
                           (:Float64, :Float64, :d),
                           (:Complex64, :Float32, :c),
                           (:Complex128, :Float64, :z))
    @eval begin
        function maxNorm(x::DistMultiVec{$elty})
            nm = Ref{$relty}(zero($relty))
            err = ccall(($(string("ElMaxNormDistMultiVec_", ext)), libEl), Cuint,
                        (Ptr{Void}, Ref{$relty}), x.obj, nm)
            err == 0 || error("something is wrong here!")
            return nm[]
        end

        function entrywiseNorm(x::DistMultiVec{$elty}, p::Real)
            nm = Ref{$relty}(zero($relty))
            err = ccall(($(string("ElEntrywiseNormDistMultiVec_", ext)), libEl), Cuint,
                        (Ptr{Void}, $relty, Ref{$relty}), x.obj, p, nm)
            err == 0 || error("something is wrong here!")
            return nm[]
        end
    end
end
