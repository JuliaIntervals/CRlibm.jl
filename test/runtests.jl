using Test

using CRlibm

# Float64
@test CRlibm.cos(0.5, RoundDown) == 0.8775825618903726
@test CRlibm.cos(0.5, RoundUp) == 0.8775825618903728
@test CRlibm.cos(0.5, RoundNearest) == cos(0.5) == 0.8775825618903728
@test CRlibm.cos(1.6, RoundToZero) == -0.029199522301288812
@test CRlibm.cos(1.6, RoundDown) == -0.029199522301288815
@test CRlibm.cos(0.5) == CRlibm.cos(0.5, RoundNearest)

# Float32
@test CRlibm.cos(0.5f0, RoundDown) == 0.87758255f0
@test CRlibm.cos(0.5f0, RoundUp) == 0.8775826f0
@test CRlibm.cos(0.5f0, RoundNearest) == cos(0.5f0) == 0.87758255f0
@test CRlibm.cos(1.6f0, RoundToZero) == -0.029199544f0
@test CRlibm.cos(1.6f0, RoundDown) == -0.029199546f0
@test CRlibm.cos(0.5f0) == CRlibm.cos(0.5f0, RoundNearest)

# Float16
@test CRlibm.cos(Float16(0.5), RoundDown) == Float16(0.8774)
@test CRlibm.cos(Float16(0.5), RoundUp) == Float16(0.878)
@test CRlibm.cos(Float16(0.5), RoundNearest) == cos(Float16(0.5)) == Float16(0.8774)
@test CRlibm.cos(Float16(1.6), RoundToZero) == Float16(-0.02881)
@test CRlibm.cos(Float16(1.6), RoundDown) == Float16(-0.02882)
@test CRlibm.cos(Float16(0.5)) == CRlibm.cos(Float16(0.5), RoundNearest)

# One failing example from #45
@test CRlibm.log10(10.0, RoundUp) == 1.0

# Functions whose `_rz` versions are macros in crlibm.h
@test CRlibm.exp(0.5, RoundToZero) == CRlibm.exp(0.5, RoundDown)
@test CRlibm.acos(0.5, RoundToZero) == CRlibm.acos(0.5, RoundDown)

# Arguments that are not floating-point numbers
@test CRlibm.sin(1, RoundDown) == CRlibm.sin(1.0, RoundDown)
@test CRlibm.sin(1//2, RoundUp) == CRlibm.sin(0.5, RoundUp)
@test_throws ArgumentError CRlibm.sin(π, RoundDown)
@test_throws ArgumentError CRlibm.sin(1//3, RoundUp)
@test_throws ArgumentError CRlibm.sin(2^53 + 1, RoundDown)
@test isnan(CRlibm.sin(NaN, RoundDown))

# Comparison with MPFR
big_atanpi(x) = atan(x) / π
big_function(f) = f === :atanpi ? big_atanpi : getfield(Base, f)

function reference(f, x, r)
    setprecision(BigFloat, 1024) do
        return typeof(x)(big_function(f)(BigFloat(x)), r)
    end
end

domain(f) = f ∈ (:asin, :acos) ? (-1.0, 1.0) :
            f ∈ (:log, :log2, :log10) ? (0.0, 1000.0) :
            f === :log1p ? (-1.0, 1000.0) : (-20.0, 20.0)

is_pi(f) = f ∈ (:sinpi, :cospi, :tanpi, :atanpi)

@testset "$f" for f in CRlibm.functions
    ff = getfield(CRlibm, f)
    lo, hi = domain(f)
    for k in 1:500, T in (Float64, Float32)
        x = T(lo + (hi - lo) * mod(k * 0.6180339887498949, 1))
        for r in (RoundDown, RoundUp, RoundNearest, RoundToZero)
            @test ff(x, r) === reference(f, x, r)
        end
    end
    for i in 0x0000:0xffff
        x = reinterpret(Float16, i)
        (isfinite(x) && lo <= x <= hi) || continue
        x == lo && f ∈ (:log, :log2, :log10, :log1p) && continue
        is_pi(f) && isinteger(2x) && continue
        for r in (RoundDown, RoundUp, RoundNearest, RoundToZero)
            @test ff(x, r) === reference(f, x, r)
        end
    end
end

# Float32 result that lies close to the middle of two Float32 numbers
@test CRlibm.sinh(Float32(0x1.250bfep-11), RoundNearest) === Float32(0x1.250bfep-11)

# Inputs for which a library built with fused multiply-adds is wrong
@test CRlibm.tan(0.1, RoundUp) >= tan(big(0.1))
@test CRlibm.sin(1e9, RoundDown) <= sin(big(1e9))
@test CRlibm.exp(1.0, RoundUp) >= exp(big(1.0))
@test CRlibm.log1p(-0x1.852ea01927fc8p-7, RoundDown) <= log1p(big(-0x1.852ea01927fc8p-7))
@test CRlibm.log2(0x1.9e37cb67e91a2p+0, RoundDown) <= log2(big(0x1.9e37cb67e91a2p+0))

function my_eps(prec::Int)
    ldexp(eps(Float64), 53-prec)
end

function my_eps(x::BigFloat)  # only works for precision >= 10?
    my_eps(precision(x) - exponent(x))
end


is_log(f) = string(f)[1:3] == "log"

function do_test(f, val)
    a = f(val, RoundDown)
    b = f(val, RoundUp)
    @test b - a == eps(a) || b - a == eps(b) || b - a == 0
end

function test_CRlibm(functions)
    @show functions
    for f in functions
        #println("Testing CRlibm.$f")

        ff = getfield(CRlibm, f)  # the actual Julia function

        for val in (0.51, 103.2, -17.1, -0.00005, 1)

            #@show f, val

            val <= 0.0 && is_log(f) && continue
            abs(val) > 1 && f ∈ (:asin, :acos) && continue

            do_test(ff, val)
        end
    end
end

function test_MPFR()
    for f in CRlibm.MPFR_functions
        #println("Testing CRlibm.$f")

        ff = getfield(CRlibm, f)  # the actual Julia function

        for val in (0.51, 103.2, -17.1, -0.00005)
            #print(val, " ")

            #@show f, val

            val <= 0.0 && is_log(f) && continue
            abs(val) > 1 && f ∈ (:asin, :acos) && continue

            for prec in (20, 100, 1000)

                setprecision(BigFloat, prec) do
                    val = BigFloat(val)
                    do_test(ff, val)
                end

            end
        end
    end
end


if !(CRlibm.is_32_bit)
    println("Testing CRlibm")
    test_CRlibm(CRlibm.functions)
    # This will currently fail on the :sinpi etc. functions (that are not defined in MPFR) if MPFR is already enabled because the CRlibm library could not be found


    println("Testing shadowing MPFR")
    CRlibm.setup(true)
    test_CRlibm(CRlibm.MPFR_functions)
end

println("Testing MPFR")
test_MPFR()
