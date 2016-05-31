module Juliet

using JLD

include("types.jl")

function new_lesson(name; description="", version=v"1", authors=[],
	keywords=[], questions=[])
	return Types.Lesson(name, description, version, authors, keywords, questions)
end

function add_question!(lesson::Types.Lesson, question::Types.AbstractQuestion)
	push!(lesson.questions, question)
end

function package_lesson(lesson::Types.Lesson, filename)
	save(filename, "lesson: $(lesson.name)", lesson)
end

function package_course(course::Types.Course, filename)
	save(filename, "course: $(lesson.name)", course)
end

end

end # module
