using Juliet

text = """
name = "Basic syntax"
description = "Some basic syntax stuff"
authors = ["Matthew Lake"]
keywords = ["basic", "syntax"]

[[questions]]
type = "InfoQuestion"
text = "This lesson will teach you about basic Julia syntax"

[[questions]]
type = "SyntaxQuestion"
text = "Set `a` to be 1"
answer = "a = 1"
hints = []

[[questions]]
type = "SyntaxQuestion"
text = "Assign `b` to be twice `a`"
answer = "b = 2a"
hints = []

[[questions]]
type = "MultiQuestion"
text = "Is this fun?"
options = ["no", "yes"]
answer = 2
hints = []
"""

lesson = Juliet.Convert.to_lesson(TOML.parse(text))

c = Juliet.Types.Course("Basic Syntax Lesson", "", v"1", [], [], [lesson])
Juliet.register(c)

juliet()
