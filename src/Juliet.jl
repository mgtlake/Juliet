module Juliet

using JLD

include("types.jl")

export juliet

println("""
	Welcome to Juliet, the Julia Interative Educational Tutor.
	Type `juliet()` to get started""")

macro tryprogress(ex)
	if isdefined(Main, :Atom)
		return :(Main.Atom.@progress $ex)
	else
		return ex
	end
end

macro getInput()
	if isdefined(Main, :Atom)
		return :(Main.Atom.input())
	else
		return  :(print("> "); readline())
	end
end

storeDir = "$(Pkg.dir("Juliet"))/store"

function juliet()
	println("""
	Welcome to Juliet, the Julia Interative Educational Tutor.
	Selct a lesson or course to get started, or type `!help` for information.""")
	lessons = list_courses_and_lessons()
	if length(lessons) == 0
		println("No lessons installed - exiting Juliet")
		return
	end
	while check_question(x -> !isa(parse(x), Number) ||
			!(0 < parse(Int,x) < length(lessons)))
		println("Invalid selection")
	end
end

function new_lesson(name; description="", version=v"1", authors=[],
	keywords=[], questions=[])
	return Types.Lesson(name, description, version, authors, keywords, questions)
end

function add_question!(lesson::Types.Lesson, question::Types.AbstractQuestion)
	push!(lesson.questions, question)
end

function load_lesson(filename)
	return JLD.load(filename)[1]
end

function package_lesson(lesson::Types.Lesson)
	JLD.save("$storeDir/lessons/$(lesson.name).jld", lesson.name, lesson)
end

function package_lesson(lesson::Types.Lesson, filename)
	JLD.save(filename, lesson.name, lesson)
end

function package_course(course::Types.Course)
	JLD.save("$storeDir/courses/$(course.name).jld", course.name, course)
end

function package_course(course::Types.Course, filename)
	JLD.save(filename, course.name, course)
end

function complete_lesson(lesson::Types.Lesson)
	len = length(lesson.questions)
	@tryprogress for (i, question) in enumerate(lesson.questions)
		print("$(rpad(i, length(string(len)))) / $len: ")
		println(question.text)

		currHint = 0
		if isa(question, Types.InfoQuestion)
			print("...")
			check_question(x -> true)
		elseif isa(question, Types.SyntaxQuestion)
			while (check_question(x -> parse(x) != question.answer))
				currHint = show_next_hint(currHint, question.hints)
			end
		elseif isa(question, Types.FunctionQuestion)
			while (check_question(x -> !(question.test)(x)))
				currHint = show_next_hint(currHint, question.hints)
			end
		elseif isa(question, Types.MultiQuestion)
			while (check_question(x -> int(x) != question.answer))
				currHint = show_next_hint(currHint, question.hints)
			end
		end
		show_congrats()
	end
end

function check_question(test::Function)
	return test(@getInput)
end

function show_next_hint(index::Int, hints::Array{AbstractString, 1})
	println(rand([
		"Oops - that's not quite right",
		"Almost there - Keep trying!",
		"One more try",
		"Hang in there",
		"Missed it by that much",
		"Close, but no cigar"]))
	if length(hints) <= 0 return end
	index = index % length(hints) + 1
	println(hints[index])
	return index
end

function show_congrats()
	println(rand([
		"You got it right!",
		"Great job!",
		"Keep up the great work!",
		"You're doing great!"]))
end

function list_courses_and_lessons()
	if !isdir(storeDir)
		mkdir(storeDir)
	end
	lessons = visit_folder(storeDir)
	return lessons
end

function visit_folder(folder)
	filenames = Array{AbstractString, 1}()
	for object in readdir(folder)
		object = folder * object
		if isfile(object) && ismatch(r".*\.julietlesson", object)
			push!(filenames, object)
		elseif isdir(object)
			append!(filenames, visit_folder(object * "/"))
		end
	end
	return filenames
end

end # module
