module Juliet

using FiniteStateMachine
using Match

include("types.jl")
include("convert.jl")
include("util.jl")

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

macro getInputDots()
	if isdefined(Main, :Atom)
		return :(print("..."); Main.Atom.input())
	else
		return :(print("..."); readline())
	end
end

macro print(ex...)
	if isdefined(Main, :Atom)
		return :(println($(ex...)))
	else
		return :(println($(ex...)))
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
	# @show get_packaged(Types.Lesson)
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

	function print_course_or_lesson(list, message; offset=0)
		if length(list) > 0
			println(message)
			for (i, el) in enumerate(list)
				println(rpad(i + offset, length(string(length(list)))), " - ", el.name)
			end
		end
	end

	print_course_or_lesson(courses, "Courses:")
	print_course_or_lesson(lessons, "Lessons" * (isa(currCourse, Void) ? ":" :
		" in $(currCourse.name) (type `!back` to return to the total list):");
		offset = length(courses))

	input = AbstractString{}
	while (input = @getInput;
			!isa(parse(input), Number) ||
			!(0 < parse(Int, input) <= length(total)))
		if strip(input) == "!back" break end
		@print("Invalid selection")
	end
	@print()

	if strip(input) == "!back"
		choose_lesson(get_packaged(Types.Lesson), get_packaged(Types.Course))
		return
	end
	selection = total[parse(Int, input)]
	if in(selection, lessons)
		complete_lesson(selection)
		if isa(currCourse, Void) && selection != last(total)
			@print("Continue to next lesson in course? y/n")
			while (input = strip(lowercase(@getInput));
					!(input in ["yes", "y", "no", "n"]))
				@print("Invalid selection")
			end
			if input in ["yes", "y"]
				complete_lesson(total[getindex(total, selection) + 1])
			else return end
		end
	else
		choose_lesson(selection.lessons, []; currCourse=selection)
	end
end

function print_question(question, index, len)
	print("$(rpad(index, length(string(len)))) / $len: ")
	@print(question.text)
	flush(STDOUT)
end

"""
Go through a lesson's questions
"""
function complete_lesson(lesson::Types.Lesson)
	fsm = state_machine(Dict(
		"initial" => "continuing",
		"final" => "done",
		"events" => [Dict(
				"name" => "ask",
				"from" => "continuing",
				"to" => "asking"
			), Dict(
				"name" => "next",
				"from" => ["asking", "hinting"],
				"to" => "continuing"
			), Dict(
				"name" => "reject",
				"from" => ["asking", "hinting"],
				"to" => "hinting"
			), Dict(
				"name" => "quit",
				"from" => ["continuing", "asking", "hinting"],
				"to" => "done"
			)
		]
	))

	@print("Starting ", lesson.name)
	@tryprogress for (i, question) in enumerate(lesson.questions)
		fire(fsm, "ask")
		print_question(question, i, length(lesson.questions))

		currHint = 0
		isinfo = isa(question, Types.InfoQuestion)
		condition = @match question begin
			info::Types.InfoQuestion => x -> true
			syntax::Types.SyntaxQuestion => x -> parse(x) == question.answer
			fun::Types.FunctionQuestion => x -> (question.test)(x)
			multi::Types.MultiQuestion => begin
					@print("Options:")
					for (i, option) in enumerate(question.options)
						@print(rpad(i, length(string(length(question.options)))),
							" - ", option)
					end
					x -> isa(parse(x), Number) && parse(Int, x) == question.answer
				end
		end

		while true
			input = if isinfo @getInputDots else @getInput end
			if strip(input) == "!skip"
				fire(fsm, "next")
				break
			end
			if strip(input) == "!quit"
				fire(fsm, "quit")
				break
			end
			if strip(input) == "!help"
				show_help()
				continue
			end
			if condition(input)
				fire(fsm, "next")
				if !isinfo show_congrats() end
				break
			else
				fire(fsm, "reject")
				show_hint(question.hints)
			end
		end

		if fsm.current == "done" break end
	end
	@print("Finished ", lesson.name)
end

function show_help()
	@print("""
	HELP:
		`...`   -> press [Enter] to continue
		[Enter] -> submit answer
		`!skip` -> go to next question
		`!quit` -> exit Juliet
	""")
end

"""
Show an encouraging message and a hint
"""
function show_hint(hints::Array{AbstractString, 1})
	@print(rand([
		"Oops - that's not quite right",
		"Almost there - Keep trying!",
		"One more try",
		"Hang in there",
		"Missed it by that much",
		"Close, but no cigar"]))
	if length(hints) > 0
		@print(rand(hints))
	end
end

"""
Show a congratulatory message
"""
function show_congrats()
	@print(rand([
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
	return filter(x -> isa(x, filterType), map(Util.load_packaged, packages))
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
