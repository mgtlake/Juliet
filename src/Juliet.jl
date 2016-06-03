module Juliet

using JLD
using Atom

include("types.jl")

export juliet

function juliet()
	println("""
	Welcome to Juliet, the Julia Interative Educational Tutor.
	Selct a lesson or course to get started, or type `!help` for information.
	""")
	list_courses_and_lessons()
end

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

		currHint = 0
		if isa(question, Types.InfoQuestion)
			print("...")
			readline()
		elseif isa(question, Types.SyntaxQuestion)
			while (print("> "); parse(readline()) != question.answer)
				currHint = show_next_hint(currHint, question.hints)
			end
		elseif isa(question, Types.FunctionQuestion)
			while (print("> "); !(question.test)(readline()))
				currHint = show_next_hint(currHint, question.hints)
			end
		elseif isa(question, Types.FunctionQuestion)
			while (print("> "); int(readline()) != question.answer)
				currHint = show_next_hint(currHint, question.hints)
			end
		end
	end
end

function show_next_hint(index::Int, hints::Array{AbstractString, 1})
	println(rand([
		"Oops - that's not quite right",
		"Almost there - Keep trying!",
		"One more try",
		"Hang in there",
		"Missed it by that much"]))
	if length(hints) <= 0 return end
	index = index % length(hints) + 1
	println(hints[index])
	return index
end

function list_courses_and_lessons()
	storeDir = "$(Pkg.dir("Juliet"))/store"
	if !isdir(storeDir)
		mkdir(storeDir)
	end
	@show visit_folder(storeDir)
end

function visit_folder(folder)
	filenames = Array{AbstractString, 1}()
	for object in readdir(folder)
		if isfile(object) && split(object, ".")[end] == "julietlesson"
			push!(filenames, object)
		elseif isdir(object)
			append!(filenames, visit_folder(object * "/"))
		end
	end
	return filenames
end

end # module
