module Juliet

using JLD
using Atom

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

function complete_lesson(lesson::Types.Lesson)
	len = length(lesson.questions)
	@progress for (i, question) in enumerate(lesson.questions)
		print("$(rpad(i, length(string(len)))) / $len: ")
		println(question.text)

		if isa(question, Types.InfoQuestion)
			print("...")
			readline()
		elseif isa(question, Types.SyntaxQuestion)
			while (print("> "); parse(readline()) != question.answer) end
		elseif isa(question, Types.FunctionQuestion)
			while (print("> "); !(question.test)(readline())) end
		elseif isa(question, Types.FunctionQuestion)
			while (print("> "); int(readline() != question.answer) end
		end
	end
end

end # module
