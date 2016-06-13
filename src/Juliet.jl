module Juliet

using JLD
using FileIO

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
		return :(print("> "); readline())
	end
end

storeDir = "$(Pkg.dir("Juliet"))/store"

function juliet()
	println("""
	Welcome to Juliet, the Julia Interative Educational Tutor.
	Selct a lesson or course to get started, or type `!help` for information.""")
	choose_lesson()
end

function choose_lesson()
	lessons, courses = get_lessons(), get_courses()
	total = union(lessons, courses)
	if length(total) == 0
		println("No lessons or courses installed - exiting Juliet")
		return
	end

	if length(courses) > 0
		println("Courses:")
		for (i, course) in enumerate(map(remove_location, courses))
			println("$(rpad(i, length(string(length(courses))))) - $course")
		end
	end
	if length(lessons) > 0
		println("Lessons:")
		for (i, lesson) in enumerate(map(remove_location, lessons))
			println("$(rpad(i + length(courses), length(string(length(lessons))))) - $lesson")
		end
	end

	input = AbstractString{}
	while (input = @getInput;
			!isa(parse(input), Number) ||
			!(0 < parse(Int, input) <= length(total)))
		println("Invalid selection")
	end
	selection = total[parse(Int, input)]
	if in(selection, lessons)
		complete_lesson(load_lesson(selection))
	else

	end
end

function remove_location(filename)
	return replace(filename, storeDir, "")
end

function new_lesson(name; description="", version=v"1", authors=[],
	keywords=[], questions=[])
	return Types.Lesson(name, description, version, authors, keywords, questions)
end

function add_question!(lesson::Types.Lesson, question::Types.AbstractQuestion)
	push!(lesson.questions, question)
end

function load_lesson(filename)
	return last(first(JLD.load(filename)))
end

function package_lesson(lesson::Types.Lesson)
	package_lesson(lesson, "$storeDir/lessons/$(lesson.name).julietlesson")
end

function package_lesson(lesson::Types.Lesson, filename)
	JLD.save(File(DataFormat{:JLD}, filename), lesson.name, lesson)
end

function package_course(course::Types.Course)
	package_course(course, "$storeDir/courses/$(course.name).julietcourse")
end

function package_course(course::Types.Course, filename)
	JLD.save(File(DataFormat{:JLD}, filename), course.name, course)
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

function get_courses()
	courseDir = "$storeDir/courses"
	if !isdir(courseDir)
		mkdir(courseDir)
	end
	courses = visit_folder(courseDir)
	return courses
end

function get_lessons()
	lessonDir = "$storeDir/lessons"
	if !isdir(lessonDir)
		mkdir(lessonDir)
	end
	lessons = visit_folder(lessonDir)
	return lessons
end

function visit_folder(folder)
	filenames = Array{AbstractString, 1}()
	for object in readdir(folder)
		object = "$folder/$object"
		if isfile(object) && ismatch(r".*\.julietlesson", object)
			push!(filenames, object)
		elseif isdir(object)
			append!(filenames, visit_folder(object * "/"))
		end
	end
	return filenames
end

end # module
