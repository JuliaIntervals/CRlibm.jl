
# Instructions:

#=
1. Download the source code from
    http://lipforge.ens-lyon.fr/frs/download.php/162/crlibm-1.0beta4.tar.gz

2. Decompress it:
    tar xzvf crlibm-1.0beta4.tar.gz

3. In the resulting crlibm-1.0beta4 directory, run (on Mac):

    export CFLAGS=-fpic
    ./configure
    make

    gcc -L. -shared -o libcrlibm.dylib *.o   # Mac

    gcc -L. -shared -o libcrlibm.so *.o   # Linux


4. Add the directory where the shared library is to Base.DL_LOAD_PATH

=#


module CRlibm

include("../deps/deps.jl")

import Base:
    sin, cos, tan, exp, log

export sin, cos, tan, exp, log


## Generate wrappers of crlibm shared library:

for f in (:sin, :cos, :tan, :exp, :log)
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
