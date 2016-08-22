using Juliet
using Base.Test

## Juliet.jl
# @tryprogress
@test Juliet.@tryprogress(:(1+1)) == :(1+1)

# @getInput
# @test Juliet.@getInput() == :(readline())

# choose_lesson

# print_options

# complete_lesson

# get_input

# ask

# validate
@test Juliet.validate(Juliet.Types.InfoQuestion("info"), "anything") == true
@test Juliet.validate(Juliet.Types.SyntaxQuestion("syntax", ["hint"], :(1+1)), "wrong") == false
@test Juliet.validate(Juliet.Types.SyntaxQuestion("syntax", ["hint"], :(1+1)), "1+1") == true
@test Juliet.validate(Juliet.Types.MultiQuestion("multi", ["hint"], ["option 1"], 1), "2") == false
@test Juliet.validate(Juliet.Types.MultiQuestion("multi", ["hint"], ["option 1"], 1), "1") == true

# show_hint

# show_congrats

# setup_function_file

# filename
# @test filename(Juliet.Types.FunctionQuestion("function", ["hint"], [[123], [123]], ""))

# register
@test Juliet.courses == []
question = Juliet.Types.InfoQuestion("info")
lesson = Juliet.Types.Lesson("Test course", "description", v"1", ["Author"],
	["Keyword"], [question])
course = Juliet.Types.Course("Test course", "description", v"1", ["Author"],
	["Keyword"], [lesson])
Juliet.register(course)
@test Juliet.courses == [course]
Juliet.register(course)
@test Juliet.courses == [course]
