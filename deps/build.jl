# Modified from Diercxk.jl:
# https://github.com/kbarbary/Dierckx.jl/blob/master/deps/build.jl  (3-clause BSD license)

# do it by hand since problem with BinDeps


suffix = ""

@unix_only begin
    download = @osx ? `curl -O` : `wget`
    suffix = @osx ? "dylib" : "so"
end

@windows_only begin
    error("Package not currently available on Windows")
end

lib_name = "crlibm-1.0beta4"

file = "http://lipforge.ens-lyon.fr/frs/download.php/162/$(lib_name).tar.gz"

println("Working in ", pwd())
src_dir = "src"
cd(src_dir)

#run(`$(download) $file`)
#run(`tar xzvf $(lib_name).tar.gz`)

#srcdir = "$(src_dir)/$(lib_name)"

cd(lib_name)
println("Working in ", pwd())

suffix = @osx? "dylib" : "so"
run(`./configure CFLAGS=-fpic`)
println("Working in ", pwd())

run(`make`)
run(`make -f ../shared.mk SUFFIX=$suffix`)
