using Juliet
using Base.Test

include("unittest.jl")

f = x -> strip(x) != ""
lesson = Juliet.new_lesson("1234")
Juliet.add_question!(lesson, Juliet.Types.FunctionQuestion("question 1",
	["hint 1", "hint 2", "hint 3"], f))
# Juliet.complete_lesson(lesson)
