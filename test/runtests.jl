using Juliet
using Base.Test

# write your own tests here
@test 1 == 1

f(x::AbstractString) = strip(x) != ""
lesson = Juliet.new_lesson("1234")
Juliet.add_question!(lesson, Juliet.Types.FunctionQuestion("question 1",
	["hint 1", "hint 2", "hint 3"], x->f(x)))
Juliet.complete_lesson(lesson)
