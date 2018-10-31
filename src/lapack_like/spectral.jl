# Sign
# TODO: Move this to ./funcs.jl
const ElSignScaling = Cuint
const SIGN_SCALE_NONE = ElSignScaling(0)
const SIGN_SCALE_DET  = ElSignScaling(1)
const SIGN_SCALE_FROB = ElSignScaling(2)

struct SignCtrl{T<:ElFloatType}
    maxIts::ElInt
    tol::T
    power::T
    scaling::ElSignScaling
    progress::ElBool
end
function SignCtrl(::Type{T};
    maxIts = 100,
    tol = 0,
    power = 1,
    scaling = SIGN_SCALE_FROB,
    progress::Bool = false) where {T<:ElFloatType}

    SignCtrl{T}(ElInt(maxIts),
        T(tol),
        T(power),
        ElSignScaling(scaling),
        ElBool(progress))
end

# Schur
struct HessQRCtrl
    distAED::ElBool
    blockHeight::ElInt
    blockWidth::ElInt
end
function HessQRCtrl(
    distAED::Bool = false,
    blockHeight = 32,
    blockWidth = 32)

    HessQRCtrl(ElBool(distAED),ElInt(blockHeight),ElInt(blockWidth))
end

struct SDCCtrl{T<:ElFloatType}
    cutoff::ElInt
    maxInnerIts::ElInt
    maxOuterIts::ElInt
    tol::T
    spreadFactor::T
    random::ElBool
    progress::ElBool
    signCtrl::SignCtrl{T}
end
function SDCCtrl(::Type{T};
    cutoff = 256,
    maxInnerIts = 2,
    maxOuterIts = 10,
    tol = 0,
    spreadFactor = 1e-6,
    random::Bool = true,
    progress::Bool = false,
    signCtrl = SignCtrl(T)) where {T<:ElFloatType}

    SDCCtrl{T}(ElInt(cutoff),
        ElInt(maxInnerIts),
        ElInt(maxOuterIts),
        T(tol),
        T(spreadFactor),
        ElBool(random),
        ElBool(progress),
        signCtrl)
end

struct SchurCtrl{T<:ElFloatType}
    useSDC::ElBool
    qrCtrl::HessQRCtrl
    sdcCtrl::SDCCtrl{T}
end
function SchurCtrl(::Type{T};
    useSDC::Bool = false,
    qrCtrl::HessQRCtrl = HessQRCtrl(),
    sdcCtrl::SDCCtrl{T} = SDCCtrl(T)) where {T<:ElFloatType}

    SchurCtrl{T}(ElBool(useSDC),
        qrCtrl,
        sdcCtrl)
end

# Pseueospectra

struct SnapshotCtrl
    realSize::ElInt
    imagSize::ElInt
    imgSaveFreq::ElInt
    numSaveFreq::ElInt
    imgDispFreq::ElInt
    imgSaveCount::ElInt
    numSaveCount::ElInt
    imgDispCount::ElInt
    imgBase::Cstring
    numBase::Cstring
    imgFormat::FileFormat
    numFormat::FileFormat
    itCounts::ElBool
end
function SnapshotCtrl(realSize=0,
    imagSize=0,
    imgSaveFreq=-1,
    numSaveFreq=-1,
    imgDispFreq=-1,
    imgSaveCount=0,
    numSaveCount=0,
    imgDispCount=0,
    imgBase::String="ps",
    numBase::String="ps",
    imgFormat=PNG,
    numFormat=ASCII_MATLAB,
    itCounts::Bool=true)

    SnapshotCtrl(Cint(realSize),
        Cint(imagSize),
        Cint(imgSaveFreq),
        Cint(numSaveFreq),
        Cint(imgDispFreq),
        Cint(imgSaveCount),
        Cint(numSaveCount),
        Cint(imgDispCount),
        Cstring(Symbol(imgBase)),
        Cstring(Symbol(numBase)),
        imgFormat,
        numFormat,
        ElBool(itCounts))
end

const ElPseudospecNorm = Cuint
const PS_TWO_NORM = ElPseudospecNorm(0)
const PS_ONE_NORM = ElPseudospecNorm(1)

struct PseudospecCtrl{T<:ElFloatType}
    norm::ElPseudospecNorm
    blockWidth::ElInt
    schur::ElBool
    forceComplexSchur::ElBool
    forceComplexPs::ElBool
    schurCtrl::SchurCtrl{T}
    maxIts::ElInt
    tol::T
    deflate::ElBool
    arnoldi::ElBool
    basisSize::ElInt
    reorthog::ElBool
    progress::ElBool
    snapCtrl::SnapshotCtrl
end
function PseudospecCtrl(::Type{T};
    norm = PS_TWO_NORM,
    blockWidth = 10,
    schur::Bool = true,
    forceComplexSchur::Bool = false,
    forceComplexPs::Bool = false,
    schurCtrl = SchurCtrl(T),
    maxIts = 50,
    tol = 1e-6,
    deflate::Bool = true,
    arnoldi::Bool = true,
    basisSize = 10,
    reorthog::Bool = true,
    progress::Bool = false,
    snapCtrl = SnapshotCtrl()) where {T<:ElFloatType}

    PseudospecCtrl{T}(ElPseudospecNorm(norm),
        ElInt(blockWidth),
        ElBool(schur),
        ElBool(forceComplexSchur),
        ElBool(forceComplexPs),
        schurCtrl,
        ElInt(maxIts),
        T(tol),
        ElBool(deflate),
        ElBool(arnoldi),
        ElInt(basisSize),
        ElBool(reorthog),
        ElBool(progress),
        snapCtrl)
end

struct SpectralBox{T}
    center::Complex{T}
    realWidth::T
    imagWidth::T
end

# SVD
struct SVDCtrl{T<:ElFloatType}
    seqQR::ElBool
    valChanRatio::Cdouble
    fullChanRatio::Cdouble
    thresholded::ElBool
    relative::ElBool
    tol::T
end
function SVDCtrl(::Type{T};
    seqQR = false,
    valChanRatio = 1.2,
    fullChanRatio = 1.5,
    thresholded = false,
    relative = true,
    tol = 0.0) where {T<:ElFloatType}

    SVDCtrl{T}(ElBool(seqQR),
        Cdouble(valChanRatio),
        Cdouble(fullChanRatio),
        ElBool(thresholded),
        ElBool(relative),
        T(tol))
end

for (elty, ext) in ((:Float32, :s),
                    (:Float64, :d),
                    (:ComplexF32, :c),
                    (:ComplexF64, :z))
    for mattype in ("", "Dist")
        mat = Symbol(mattype, "Matrix")
        @eval begin

            function eigvalsTridiag(d::$mat{real($elty)}, dSub::$mat{$elty}, sort::SortType = ASCENDING)
                w = $mat(real($elty))
                ElError(ccall(($(string("ElHermitianTridiagEig", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, SortType),
                    d.obj, dSub.obj, w.obj, sort))
                return w
            end

            function eigTridiag(d::$mat{real($elty)}, dSub::$mat{$elty}, sort::SortType = ASCENDING)
                w = $mat(real($elty))
                Z = $mat($elty)
                ElError(ccall(($(string("ElHermitianTridiagEigPair", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, SortType),
                    d.obj, dSub.obj, w.obj, Z.obj, sort))
                return w, Z
            end

            function eigvalsHermitian(uplo::UpperOrLower, A::$mat{$elty}, sort::SortType = ASCENDING)
                w = $mat(real($elty))
                ElError(ccall(($(string("ElHermitianEig", mattype, "_", ext)), libEl), Cuint,
                    (UpperOrLower, Ptr{Cvoid}, Ptr{Cvoid}, SortType),
                    uplo, A.obj, w.obj, sort))
                return w
            end

            function eigvalsHermitian(pencil::Pencil, uplo::UpperOrLower, A::$mat{$elty}, B::$mat{$elty}, sort::SortType = ASCENDING)
                w = $mat(real($elty))
                ElError(ccall(($(string("ElHermitianGenDefEig", mattype, "_", ext)), libEl), Cuint,
                    (Pencil, UpperOrLower, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, SortType),
                    pencil, uplo, A.obj, B.obj, w.obj, sort))
                return w
            end

            function eigHermitian(uplo::UpperOrLower, A::$mat{$elty}, sort::SortType = ASCENDING)
                w = $mat(real($elty))
                Z = $mat($elty)
                ElError(ccall(($(string("ElHermitianEigPair", mattype, "_", ext)), libEl), Cuint,
                    (UpperOrLower, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, SortType),
                    uplo, A.obj, w.obj, Z.obj, sort))
                return w, Z
            end

            function eigvalsGeneral(A::$mat{$elty}, fullTriangle = false)
                w = $mat(complex($elty))
                ElError(ccall(($(string("ElSchur", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, ElBool),
                    A.obj, w.obj, fullTriangle))
                return w
            end

            function LinearAlgebra.svdvals!(A::$mat{$elty})
                s = $mat(real($elty))
                ElError(ccall(($(string("ElSingularValues", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}),
                    A.obj, s.obj))
                return s
            end

            function LinearAlgebra.svdvals!(A::$mat{$elty}, ctrl::SVDCtrl{real($elty)})
                s = $mat(real($elty))
                ElError(ccall(($(string("ElSingularValuesX", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, SVDCtrl{real($elty)}),
                    A.obj, s.obj, ctrl))
                return s
            end

            function LinearAlgebra.svd(A::$mat{$elty})
                U = $mat($elty)
                s = $mat(real($elty))
                V = $mat($elty)
                ElError(ccall(($(string("ElSVD", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                    A.obj, U.obj, s.obj, V.obj))
                return U, s, V
            end

            function LinearAlgebra.svd!(A::$mat{$elty}, ctrl::SVDCtrl{real($elty)})
                U = $mat($elty)
                s = $mat(real($elty))
                V = $mat($elty)
                ElError(ccall(($(string("ElSVDX", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, SVDCtrl{real($elty)}),
                    A.obj, U.obj, s.obj, V.obj, ctrl))
                return U, s, V
            end

            function spectralPortrait(A::$mat{$elty}, realSize::ElInt, imagSize::ElInt, psCtrl::PseudospecCtrl{real($elty)}=PseudospecCtrl(real($elty)))
                invNormMap = $mat(real($elty))
                box = Ref{SpectralBox{real($elty)}}()
                ElError(ccall(($(string("ElSpectralPortraitX", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, ElInt, ElInt, Ref{SpectralBox{real($elty)}},PseudospecCtrl{real($elty)}),
                    A.obj, invNormMap.obj, realSize, imagSize, box, psCtrl))
                return invNormMap, box[]
            end

            function spectralWindow(A::$mat{$elty}, center::Complex{real($elty)}, realWidth::real($elty), imagWidth::real($elty), realSize::ElInt, imagSize::ElInt, psCtrl::PseudospecCtrl{real($elty)}=PseudospecCtrl(real($elty)))
                invNormMap = $mat(real($elty))
                ElError(ccall(($(string("ElSpectralWindowX", mattype, "_", ext)), libEl), Cuint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Complex{real($elty)}, real($elty), real($elty), ElInt, ElInt, PseudospecCtrl{real($elty)}),
                    A.obj, invNormMap.obj, center, realWidth, imagWidth, realSize, imagSize, psCtrl))
                return invNormMap
            end

        end
    end
end
