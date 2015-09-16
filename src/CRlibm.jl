
# Instructions:

#=
1. Download the source code from
    http://lipforge.ens-lyon.fr/frs/download.php/162/crlibm-1.0beta4.tar.gz

2. Decompress it:
    tar xzvf crlibm-1.0beta4.tar.gz

3. In the resulting crlibm-1.0beta4 directory, run (on Mac):
    gcc -shared -o crlibm.dylib *.o -lcrlibm

On Linux, presumably change  crlibm.dylib  to  crlibm.so

4. Move crlibm.dylib  or  crlibm.so  to this directory
=#



module CRlibm

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

        @eval ($f)(x::Float64, $mode) = ccall(($fname, "crlibm"), Float64, (Float64,), x)
    end
end

end



## OUTPUT:

# julia> cos(0.5, RoundDown)
# 0.8775825618903726

# julia> cos(0.5, RoundUp)
# 0.8775825618903728

# julia> cos(0.5, RoundNearest)
# 0.8775825618903728
