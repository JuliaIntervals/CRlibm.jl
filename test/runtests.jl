using CRlibm
using Compat

using Base.Test

@test cos(0.5, RoundDown) == 0.8775825618903726
@test cos(0.5, RoundUp) == 0.8775825618903728
@test cos(0.5, RoundNearest) == cos(0.5) == 0.8775825618903728
@test cos(1.6, RoundToZero) == -0.029199522301288812
@test cos(1.6, RoundDown) == -0.029199522301288815

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

function test_CRlibm(function_list)
    @show function_list
    for f in function_list
        #println("Testing CRlibm.$f")

        ff = eval(f)  # the actual Julia function

        for val in (0.51, 103.2, -17.1, -0.00005, 1)

            #@show f, val

            val <= 0.0 && is_log(f) && continue
            abs(val) > 1 && f ∈ (:asin, :acos) && continue

            do_test(ff, val)
        end
    end
end

function test_MPFR()
    for f in CRlibm.MPFR_function_list
        #println("Testing CRlibm.$f")

        ff = eval(f)  # the actual Julia function

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



println("Testing CRlibm")
test_CRlibm(CRlibm.function_list)
# This will currently fail on the :sinpi etc. functions (that are not defined in MPFR) if MPFR is already enabled because the CRlibm library could not be found


println("Testing shadowing MPFR")
CRlibm.shadow_MPFR()
test_CRlibm(CRlibm.MPFR_function_list)

println("Testing MPFR")
test_MPFR()
