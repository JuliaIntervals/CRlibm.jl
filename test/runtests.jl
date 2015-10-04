using CRlibm
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

for f in CRlibm.function_list
    println("Testing CRlibm.$f")

    for val in (0.51, 103.2, -17.1, -0.00005)
        #print(val, " ")

        val <= 0.0 && is_log(f) && continue
        abs(val) > 1 && f ∈ (:asin, :acos) && continue

        ff = eval(f)  # the actual Julia function

        a = ff(val, RoundDown)
        b = ff(val, RoundUp)
        @test b - a == eps(a)

        for prec in (20, 100, 1000)
            @show prec, val
            with_bigfloat_precision(prec) do
                val = BigFloat(val)
                a = ff(val, RoundDown)
                b = ff(val, RoundUp)

                @show a, b
                @test b - a == my_eps(a)
            end
        end




    end

end
