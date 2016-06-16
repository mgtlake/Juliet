using Juliet
using Base.Test

@test Juliet.@tryprogress(:(1+1)) == :(1+1)
