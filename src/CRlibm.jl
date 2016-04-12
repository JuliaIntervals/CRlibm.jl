
module CRlibm

using Compat

unixpath = "../deps/src/crlibm-1.0beta4/libcrlibm"
const libcrlibm = joinpath(dirname(@__FILE__), unixpath)

# check from Diercxk.jl (3-clause BSD license):

use_MPFR = false

function __init__()
    # Ensure library is available.
    if (Libdl.dlopen_e(libcrlibm) == C_NULL)
        warn("CRlibm not properly installed. Try running Pkg.build(\"CRlibm\") to fix it. Falling back to use MPFR. Note that Windows is not yet supported.")

        use_MPFR = true
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


MPFR_function_list = split("exp expm1 log log1p log2 log10 "
                    * "sin cos tan asin acos atan "
                    * "sinh cosh")

MPFR_function_list = [symbol(f) for f in MPFR_function_list]


function wrap_MPFR()
    # stopgap until included in Base

    ## Generate versions of functions for MPFR until included in Base

    for f in MPFR_function_list

        if f ∉ (:tanpi, :atanpi)  # these are not in Base
            @eval import Base.$f
        end

        for (mode, symb) in [(:Nearest, "n"), (:Up, "u"), (:Down, "d"),
                             (:ToZero, "z")
                             ]

            fname = string(f, "_r", symb)

            mode1 = Expr(:quote, mode)
            mode1 = :(::RoundingMode{$mode1})

            mode_string = string("Round", mode)
            mode2 = symbol(mode_string)

            @eval function $(f)(x::BigFloat, $mode1)
                setrounding(BigFloat, $mode2) do
                    $(f)(x)
                end
            end
        end

    end

end

function wrap_CRlibm()

    for f in function_list

        if f ∉ (:tanpi, :atanpi)  # these are not in Base
            @eval import Base.$f
        end

        for (mode, symb) in [(:Nearest, "n"), (:Up, "u"), (:Down, "d"),
                             (:ToZero, "z")
                            ]

            fname = string(f, "_r", symb)

            mode = Expr(:quote, mode)
            mode = :(::RoundingMode{$mode})

            @eval ($f)(x::Float64, $mode) = ccall(($fname, libcrlibm), Float64, (Float64,), x)
        end
    end

end

function shadow_MPFR()
    for f in function_list

        if f ∉ (:sinpi, :cospi, :tanpi, :atanpi)  # these are not in Base
            @eval import Base.$f
        end

        for (mode, symb) in [(:Nearest, "n"), (:Up, "u"), (:Down, "d"),
                             (:ToZero, "z")
                            ]

            fname = string(f, "_r", symb)

            mode1 = Expr(:quote, mode)
            mode1 = :(::RoundingMode{$mode1})

            mode2 = symbol("Round", string(mode))

            @eval function ($f)(x::Float64, $mode1)
                with_bigfloat_precision(53) do
                    Float64(($f)(BigFloat(x), $mode2))
                end
            end
            # use the functions that were previously defined for BigFloat

        end
    end
end


function wrap_generic_fallbacks()
    # avoid ambiguous definition:
    log(x::Irrational{:e}, r::RoundingMode) = 1   # this definition is consistent with Base

    for f in function_list
        @eval ($f)(x::Real, r::RoundingMode) = ($f)(float(x), r)
    end
end


wrap_MPFR()

if !use_MPFR
    wrap_CRlibm()
else
    shadow_MPFR()
end

wrap_generic_fallbacks()




end # module



## OUTPUT:

# julia> cos(0.5, RoundDown)
# 0.8775825618903726

# julia> cos(0.5, RoundUp)
# 0.8775825618903728

# julia> cos(0.5, RoundNearest)
# 0.8775825618903728
