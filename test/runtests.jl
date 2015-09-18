using CRlibm
using Base.Test

@test cos(0.5, RoundDown) == 0.8775825618903726
@test cos(0.5, RoundUp) == 0.8775825618903728
@test cos(0.5, RoundNearest) == cos(0.5) == 0.8775825618903728

for f in (sin, cos, tan, log, exp)
    for val in (0.5, 103.2, -17.1)
        val < 0.0 && f==log && continue
        @test f(val, RoundUp) - f(val, RoundDown) == eps(f(val, RoundDown))
    end
end
