module Juliet

include("types.jl")

function new_lesson(name; description="", version=v"1", authors=[],
	keywords=[], questions=[])
	return Types.Lesson(name, description, version, authors, keywords, questions)
end

function add_question!(lesson::Types.Lesson, question::Types.AbstractQuestion)
	push!(lesson.questions, question)
end
end # module
