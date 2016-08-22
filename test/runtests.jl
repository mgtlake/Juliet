using Juliet
using Base.Test

include("unittest.jl")

clean = x -> replace(x, "\r\n", "\n")

for i in filter(x -> isa(parse(x), Number), readdir("in"))
	input = joinpath("in", i)
	script = joinpath("script", "$i.jl")
	output = joinpath("out", i)
	try
		run(pipeline(pipeline(`cat $input`, `julia $script`), stdout="temp"))
	catch
		run(pipeline(pipeline(`type $input`, `julia $script`), stdout="temp"))
	end
	open("temp", "r") do f
		open("$output", "r") do g
			@test clean(readall(f)) == clean(readall(g))
		end
	end
end
