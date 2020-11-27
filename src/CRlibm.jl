module CRlibm

using CRlibm_jll

"""
    setup(use_MPFR=false)

Define correctly-rounded standard mathematical functions.
(See `CRlibm.functions` for a list.)

The functions are not exported.
Use e.g. `CRlibm.sin(0.5, RoundDown)`.

Options:

- `use_MPFR`: if `true`, the `Float64` functions just wrap corresponding MPFR functionality (`BigFloat`).

"""
function setup(use_MPFR=false)
    wrap_MPFR()

    if use_MPFR
        @info "CRlibm is shadowing MPFR."
        shadow_MPFR()
    else
        wrap_CRlibm()
    end

    wrap_generic_fallbacks()

    return use_MPFR
end

"""
Define convenience functions like `sin(x, RoundDown)` for `x::BigFloat`
"""
function wrap_MPFR()
    # stopgap until included in Base

    ## Generate versions of functions for MPFR until included in Base

    for f in MPFR_functions

        for (mode, symb) in [(:Nearest, "n"), (:Up, "u"), (:Down, "d"),
                             (:ToZero, "z")
                             ]

            fname = string(f, "_r", symb)

            mode1 = Expr(:quote, mode)
            mode1 = :(::RoundingMode{$mode1})

            mode_string = string("Round", mode)
            mode2 = Symbol(mode_string)

            @eval function $(f)(x::BigFloat, $mode1)
                setrounding(BigFloat, $mode2) do
                    Base.$f(x)
                end
            end
        end

        @eval $f(x::BigFloat) = $f(x, RoundNearest)

    end

end


function wrap_CRlibm()

    for f in functions

        for (mode, symb) in [(:Nearest, "n"), (:Up, "u"), (:Down, "d"),
                             (:ToZero, "z")
                            ]

            fname = string(f, "_r", symb)

            mode = Expr(:quote, mode)
            mode = :(::RoundingMode{$mode})

            @eval $f(x::Float64, $mode) = ccall(($fname, libcrlibm), Float64, (Float64,), x)
        end

        # Specialise for Float32 and Float16 to get the other IEEE FP types
        # working transparently as well
        @eval $f(x::Float16, r::RoundingMode) = Float16(($f)(Float64(x), r), r)
        @eval $f(x::Float32, r::RoundingMode) = Float32(($f)(Float64(x), r), r)
    end
end


function shadow_MPFR()
    for f in functions

        for (mode, symb) in [(:Nearest, "n"), (:Up, "u"), (:Down, "d"),
                             (:ToZero, "z")
                            ]

            fname = string(f, "_r", symb)

            mode1 = Expr(:quote, mode)
            mode1 = :(::RoundingMode{$mode1})

            mode2 = Symbol("Round", string(mode))

            for T in (Float16, Float32, Float64)
                @eval function $f(x::$T, $mode1)
                    setprecision(BigFloat, precision($T)) do
                        $T(($f)(BigFloat(x), $mode2), $mode2)
                    end
                end
            end
            # use the functions that were previously defined for BigFloat
        end

    end
end


function wrap_generic_fallbacks()
    # avoid ambiguous definition:

    for f in functions
        @eval $f(x::Real, r::RoundingMode) = ($f)(float(x), r)
        @eval $f(x::Real) = $f(x, RoundNearest)
    end
end



# All functions in crlibm except pow, according to section 0.4 of the PDF manual
# (page 8); source: ./deps/src/crlibm1.0beta4/docs/latex/0_getting-started.tex,
# section "Currently available functions"

const function_names = split("""exp expm1 log log1p log2 log10
                         sin cos tan asin acos atan
                         sinh cosh sinpi cospi tanpi atanpi
                      """)


const functions = map(Symbol, function_names)


## Generate wrappers of CRlibm shared library:

# Aiming for functions of the form
# cos(x::Float64, ::RoundingMode{:RoundUp}) = ccall((:cos, libcrlibm), Float64, (Float64,), x)


const MPFR_function_names = split("""exp expm1 log log1p log2 log10
                              sin cos tan asin acos atan
                              sinh cosh
                           """)

const MPFR_functions = map(Symbol, MPFR_function_names)

use_MPFR = setup()

end # module
