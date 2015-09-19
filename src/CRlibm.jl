
module CRlibm

unixpath = "../deps/src/crlibm-1.0beta4/libcrlibm"
const libcrlibm = joinpath(dirname(@__FILE__), unixpath)

# check from Diercxk.jl (3-clause BSD license):
function __init__()
    # Ensure library is available.
    if (Libdl.dlopen_e(libcrlibm) == C_NULL)
        error("CRlibm not properly installed. Run Pkg.build(\"CRlibm\")")
    end
end

export tanpi, atanpi

# All functions in crlibm except pow, according to section 0.4 of the PDF manual
# (page 8); source: ./deps/src/crlibm1.0beta4/docs/latex/0_getting-started.tex,
# section "Currently available functions"

function_list = split("exp expm1 log log1p log2 log10 "
                    * "sin cos tan asin acos atan "
                    * "sinh cosh sinpi cospi tanpi atanpi"
                    )

function_list = [symbol(f) for f in function_list]


## Generate wrappers of CRlibm shared library:

# Aiming for functions of the form
# cos(x::Float64, ::RoundingMode{:RoundUp}) = ccall((:cos, libcrlibm), Float64, (Float64,), x)

for f in function_list

    if f ∉ (:tanpi, :atanpi)  # these are not in Base
        @eval import Base.$f
    end

    for (mode, symb) in [(:Nearest, "n"), (:Up, "u"), (:Down, "d"), (:ToZero, "z")]

        fname = string(f, "_r", symb)

        mode = Expr(:quote, mode)
        mode = :(::RoundingMode{$mode})

        @eval ($f)(x::Float64, $mode) = ccall(($fname, libcrlibm), Float64, (Float64,), x)
    end
end


end # module



## OUTPUT:

# julia> cos(0.5, RoundDown)
# 0.8775825618903726

# julia> cos(0.5, RoundUp)
# 0.8775825618903728

# julia> cos(0.5, RoundNearest)
# 0.8775825618903728
