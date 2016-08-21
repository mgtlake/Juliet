using Juliet
using Base.Test

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

# show_hint

# show_congrats

# setup_function_file

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
