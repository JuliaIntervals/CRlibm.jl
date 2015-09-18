using CRlibm
using Base.Test

@test cos(0.5, RoundDown) == 0.8775825618903726
@test cos(0.5, RoundUp) = 0.8775825618903728
@test cos(0.5, RoundNearest) == 0.8775825618903728
@test cos(0.5, RoundNearest) == cos(0.5)

@test cos(0.5, RoundUp) - cos(0.5, RoundDown) == eps(cos(0.5, RoundDown))
