using Juliet
using TOML

text = """
name = "Functions TEST"
description = "All functions all the time"
authors = ["Matthew Lake"]
keywords = ["basic", "functions"]

[[questions]]
type = "FunctionQuestion"
text = "Return the same number"
tests = [["123", "123"]]
template = "# write code here"
hints = ["Just return the number you read in"]

"""

lesson = Juliet.Convert.to_lesson(TOML.parse(text))

# Write a passing file
answer = """
print(readline())
"""
dir = joinpath(homedir(), "Juliet", "FunctionQuestion")
mkpath(dir)
file = joinpath(dir, Juliet.filename(lesson.questions[1]))
open(file, "w") do f
	write(f, answer)
end

c = Juliet.Types.Course("Basic Function Lesson", "", v"1", [], [], [lesson])
Juliet.register(c)

juliet()

# rm(file)
