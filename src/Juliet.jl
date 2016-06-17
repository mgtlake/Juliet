module Juliet

using JLD
using FileIO

include("types.jl")
include("convert.jl")

export juliet

println("""
	Welcome to Juliet, the Julia Interative Educational Tutor.
	Type `juliet()` to get started
	""")

"""
Try to use a progess bar - relies on `Atom.jl`
"""
macro tryprogress(ex)
	if isdefined(Main, :Atom)
		return :(Main.Atom.@progress $ex)
	else
		return ex
	end
end

"""
Get user input in a environment agnostic manner
"""
macro getInput()
	if isdefined(Main, :Atom)
		return :(Main.Atom.input())
	else
		return :(print("> "); readline())
	end
end

storeDir = "$(Pkg.dir("Juliet"))/store"

"""
Main function to run Juliet
"""
function juliet()
	println("""
	Welcome to Juliet, the Julia Interative Educational Tutor.
	Selct a lesson or course to get started, or type `!help` for information.
	""")
	choose_lesson(get_packaged(Types.Lesson), get_packaged(Types.Course))
end

"""
Choose a lesson and complete it
"""
function choose_lesson(lessons, courses; currCourse=nothing)
	total = [courses; lessons]
	if length(total) == 0
		println("No lessons or courses installed - exiting Juliet")
		return
	end

	if length(courses) > 0
		println("Courses:")
		for (i, course) in enumerate(courses)
			println(rpad(i, length(string(length(courses)))), " - ",
				course.name)
		end
	end
	if length(lessons) > 0
		println("Lessons", isa(currCourse, Void) ? ":" :
			" in $(currCourse.name) (type `!back` to return to the total list):")
		for (i, lesson) in enumerate(lessons)
			println(rpad(i + length(courses), length(string(length(lessons)))),
				" - ", lesson.name)
		end
	end

	input = AbstractString{}
	while (input = @getInput;
			!isa(parse(input), Number) ||
			!(0 < parse(Int, input) <= length(total)))
		if strip(input) == "!back" break end
		println("Invalid selection")
	end
	println()

	if strip(input) == "!back"
		choose_lesson(get_packaged(Types.Lesson), get_packaged(Types.Course))
		return
	end
	selection = total[parse(Int, input)]
	if in(selection, lessons)
		complete_lesson(selection)
		if isa(currCourse, Void) && selection != last(total)
			println("Continue to next lesson in course? y/n")
			while (input = strip(lowercase(@getInput));
					!(input in ["yes", "y", "no", "n"]))
				println("Invalid selection")
			end
			if input in ["yes", "y"]
				complete_lesson(total[getindex(total, selection) + 1])
			else return end
		end
	else
		choose_lesson(selection.lessons, []; currCourse=selection)
	end
end

"""
Create a new lesson
"""
function new_lesson(name; description="", version=v"1", authors=[],
	keywords=[], questions=[])
	return Types.Lesson(name, description, version, authors, keywords, questions)
end

"""
Add a question to a lesson
"""
function add_question!(lesson::Types.Lesson, question::Types.AbstractQuestion)
	push!(lesson.questions, question)
end

"""
Create a new course
"""
function new_course(name; description="", version=v"1", authors=[],
	keywords=[], lessons=[])
	return Types.Course(name, description, version, authors, keywords, lessons)
end

"""
Add a question to a lesson
"""
function add_lesson!(course::Types.Course, lesson::Types.Lesson)
	push!(course.lessons, lesson)
end

"""
Load from a JLD file
"""
function load_packaged(filename)
	return last(first(JLD.load(filename)))
end

"""
Package a lesson into the default location
"""
function package_lesson(lesson::Types.Lesson)
	package_lesson(lesson, "$storeDir/lessons/$(lesson.name).julietlesson")
end

"""
Package a lesson into a custom location
"""
function package_lesson(lesson::Types.Lesson, filename)
	JLD.save(File(DataFormat{:JLD}, filename), lesson.name, lesson)
end

"""
Package a course into the default location
"""
function package_course(course::Types.Course)
	package_course(course, "$storeDir/courses/$(course.name).julietcourse")
end

"""
Package a course into a custom location
"""
function package_course(course::Types.Course, filename)
	JLD.save(File(DataFormat{:JLD}, filename), course.name, course)
end

"""
Go through a lesson's questions
"""
function complete_lesson(lesson::Types.Lesson)
	println("Starting ", lesson.name)
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
	println("Finished ", lesson.name)
end

"""
Check that the user's input satisfy the question's test
"""
function check_question(test::Function)
	return test(@getInput)
end

"""
Show an encouraging message and a hint
"""
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

"""
Show a congratulatory message
"""
function show_congrats()
	println(rand([
		"You got it right!",
		"Great job!",
		"Keep up the great work!",
		"You're doing great!"]))
end

"""
Get packaged lessons or courses
"""
function get_packaged(filterType)
	if !isdir(storeDir)
		mkdir(storeDir)
	end
	packages = visit_folder(storeDir)
	return filter(x -> isa(x, filterType), map(load_packaged, packages))
end

"""
Check for lessons and courses in a folder - acts recursively
"""
function visit_folder(folder)
	filenames = Array{AbstractString, 1}()
	for object in readdir(folder)
		object = "$folder/$object"
		if isfile(object) && ismatch(r".*\.juliet(lesson|course)", object)
			push!(filenames, object)
		elseif isdir(object)
			append!(filenames, visit_folder(object * "/"))
		end
	end
	return filenames
end

end # module
