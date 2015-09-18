# modified from the Ipopt.jl package
# https://github.com/JuliaOpt/Ipopt.jl/blob/master/deps/build.jl  (MIT license)

# and Diercxk.jl:
# https://github.com/kbarbary/Dierckx.jl/blob/master/deps/build.jl  (3-clause BSD license)

using BinDeps

suffix = ""

@unix_only begin
    suffix = @osx ? "dylib" : "so"
end

@windows_only begin
    error("Package not currently available on Windows")
end

@BinDeps.setup

libcrlibm = library_dependency("libcrlibm", aliases=["libcrlibm.so", "libcrlibm.dylib"])


provides(Sources,
        URI("http://lipforge.ens-lyon.fr/frs/download.php/162/crlibm-1.0beta4.tar.gz"),
        libcrlibm, os = :Unix)

srcdir = joinpath(BinDeps.depsdir(libcrlibm), "src", "crlibm-1.0beta4")


provides(SimpleBuild,
    (@build_steps begin
        GetSources(libcrlibm)

        @build_steps begin
            ChangeDirectory(srcdir)
            @build_steps begin
                `./configure CFLAGS=-fpic`
                `make`

                #`gcc -L. -shared -o libcrlibm.$suffix *.o`
                #pipeline(`find . -d 1 -name *.o`, `xargs gcc -L. -shared -o libcrlibm.dylib`)
                `make -f ../shared.mk SUFFIX=$suffix`
            end
        end
    end),
    libcrlibm, os = :Unix
)


@BinDeps.install Dict(:libcrlibm => :libcrlibm)
