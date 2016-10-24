# Modified from Diercxk.jl:
# https://github.com/kbarbary/Dierckx.jl/blob/master/deps/build.jl  (3-clause BSD license)

# do it by hand since problem with BinDeps


suffix = ""

@compat @static if is_unix() begin
    my_download = is_apple() ? `curl -O` : `wget`
    suffix = is_apple() ? "dylib" : "so"
end

@compat @static if is_windows() begin
    warn("On Windows, CRlibm currently just wraps MPFR, and so is slow.")
    exit(0)
end

lib_name = "crlibm-1.0beta4"
src_dir = "src"
cd(src_dir)

run(`tar xzf $(lib_name).tar.gz`)

#srcdir = "$(src_dir)/$(lib_name)"

cd(lib_name)
println("Working in ", pwd())

suffix = is_apple() ? "dylib" : "so"
run(`./configure CFLAGS=-fpic --silent`)
println("Working in ", pwd())

run(`make -s V=0`)
run(`make -s -f ../shared.mk SUFFIX=$suffix V=0`)
