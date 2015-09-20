using CRlibm
using Base.Test

@test cos(0.5, RoundDown) == 0.8775825618903726
@test cos(0.5, RoundUp) == 0.8775825618903728
@test cos(0.5, RoundNearest) == cos(0.5) == 0.8775825618903728
@test cos(1.6, RoundToZero) == -0.029199522301288812
@test cos(1.6, RoundDown) == -0.029199522301288815


is_log(f) = string(f)[1:3] == "log"

for f in CRlibm.function_list
    println("Testing CRlibm.$f")

    for val in (0.51, 103.2, -17.1, -0.00005)
        #print(val, " ")

        val <= 0.0 && is_log(f) && continue
        abs(val) > 1 && f ∈ (:asin, :acos) && continue

        ff = eval(f)  # the actual Julia function
        @test ff(val, RoundUp) - ff(val, RoundDown) == eps(ff(val, RoundDown))

    end

end
