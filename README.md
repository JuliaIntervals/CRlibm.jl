# CRlibm.jl

[![Build Status](https://travis-ci.org/dpsanders/CRlibm.jl.svg?branch=master)](https://travis-ci.org/dpsanders/CRlibm.jl)

A Julia wrapper around the [CRlibm library](http://lipforge.ens-lyon.fr/www/crlibm/). This library provides Correctly Rounded mathematical functions such as `cos` and `exp`.

## Usage

```julia
julia> cos(1.0, RoundUp)

julia> cos(1.0, RoundDown)
```

