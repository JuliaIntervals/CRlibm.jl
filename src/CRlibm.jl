
module CRlibm

# following check from Ipopt.jl:
# if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
#     include("../deps/deps.jl")
# else
#     error("CRlibm not properly installed. Please run Pkg.build(\"CRlibm\")")
# end

unixpath = "../deps/src/crlibm-1.0beta4/libcrlibm"
const libcrlibm = joinpath(dirname(@__FILE__), unixpath)

function __init__()
    # Ensure library is available.
    if (Libdl.dlopen_e(libcrlibm) == C_NULL)
        error("CRlibm not properly installed. Run Pkg.build(\"CRlibm\")")
    end
end


# imports and exports:

function_list = (:sin, :cos, :tan, :exp, :log)

for f in function_list
    @eval begin
         import Base.$f
     end
end


## Generate wrappers of CRlibm shared library:

for f in function_list
    for (mode, symb) in [(:Nearest, "n"), (:Up, "u"), (:Down, "d")  ]

        fname = symbol(f, "_r", symb)
        fname = Expr(:quote, fname)

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
