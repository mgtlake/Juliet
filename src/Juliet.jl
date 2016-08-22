__precompile__()

module Juliet

using FiniteStateMachine
using Match
using Compat

include("types.jl")
include("convert.jl")
include("util.jl")

export juliet

function __init__()
	println("""
		Welcome to Juliet, the Julia Interative Educational Tutor.
		Type `juliet()` to get started
		""")
	# Seed the rng to make testing deterministic
	srand(1)
end

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
function getInput()
	if isdefined(Main, :Atom)
		return Main.Atom.input()
	else
		return readline()
	end
end

courses = Types.Course[]

help = Dict(
	"select" => """
		HELP:
		  [Number] -> select course
		  `!back`  -> exit course
		  `!quit`  -> exit Juliet
	""",
	"lesson" => """
		HELP:
		  `...`   -> press [Enter] to continue
		  [Enter] -> submit answer
		  `!skip` -> go to next question
		  `!quit` -> exit lesson
	"""
)

"""
Main function to run Juliet
"""
function juliet()
	println("""
	Welcome to Juliet, the Julia Interative Educational Tutor.
	Selct a lesson or course to get started, or type `!help` for information.
	""")
	choose_lesson(courses)
end

"""
Choose a course, and then choose a lesson
"""
function choose_lesson(courses::Vector{Types.Course})
	@match courses begin
		[]  => begin println("No courses installed - import some packages"); return end
		[_] => begin choose_lesson(courses[1]); return end
	end

	print_options(courses, "Courses:")

	input = ""
	while (print("> "); input = getInput();
			!isa(parse(input), Number) ||
			!(0 < parse(Int, input) <= length(courses)))
		@match strip(input) begin
			"!quit" => return
			"!help" => println(help["select"])
			_       => println("Invalid selection")
		end
	end

	choose_lesson(courses[parse(Int, input)])
end

"""
Choose a lesson, then complete it
"""
function choose_lesson(course::Types.Course)
	@match courses begin
		[]  => begin println("No lessons in $(course.name) - exiting course"); return end
		[_] => begin complete_lesson(course.lessons[1]); return end
	end

	print_options(course.lessons,
		"Lessons in $(course.name) (type `!back` to return to the total list):")

	input = ""
	while (print("> "); input = getInput();
			!isa(parse(input), Number) ||
			!(0 < parse(Int, input) <= length(course.lessons)))
		@match strip(input) begin
			"!quit" => return
			"!back" => begin choose_lesson(courses); return end
			"!help" => println(help["select"])
			_       => println("Invalid selection")
		end
	end

	selection = course.lessons[parse(Int, input)]
	complete_lesson(selection)
	if selection != last(course.lessons)
		println("Continue to next lesson in course? y/n")
		while (input = strip(lowercase(getInput()));
				!(input in ["yes", "y", "no", "n"]))
			println("Invalid selection")
		end
		if input in ["yes", "y"]
			complete_lesson(course.lessons[getindex(course.lessons, selection) + 1])
		else return end
	end
end

"""
Print a list of options
"""
function print_options(list, message)
	if length(list) > 0
		println(message)
		for (i, el) in enumerate(list)
			println(rpad(i, length(string(length(list)))), " - ", el.name)
		end
	end
end

"""
Go through a lesson's questions
"""
function complete_lesson(lesson::Types.Lesson)
	fsm = state_machine(Dict(
		"initial" => "continuing",
		"final" => "done",
		"events" => [
			Dict("name" => "ask", "from" => "continuing", "to" => "asking"),
			Dict("name" => "next", "from" => ["asking", "hinting"], "to" => "continuing"),
			Dict("name" => "reject", "from" => ["asking", "hinting"], "to" => "hinting"),
			Dict("name" => "quit", "from" => ["continuing", "asking", "hinting"], "to" => "done")
		]
	))

	println("Starting ", lesson.name)
	@tryprogress for (i, question) in enumerate(lesson.questions)
		fire(fsm, "ask")
		print("$(rpad(i, length(string(length(lesson.questions))))) / $(length(lesson.questions)): ")
		ask(question)

		while fsm.current == "asking" || fsm.current == "hinting"
			input = get_input(question)
			@match strip(input) begin
				"!skip" => begin fire(fsm, "next"); break end
				"!quit" => begin fire(fsm, "quit"); break end
				"!help" => begin println(help["lesson"]); continue end
			end

			if validate(question, input)
				fire(fsm, "next")
				show_congrats(question)
			else
				fire(fsm, "reject")
				show_hint(question)
			end
		end

		if fsm.current == "done" break end
	end
	println("Finished ", lesson.name)
end

"""
Get input for a question
"""
function get_input(question)
	print("> ")
	input = getInput()
	# Remove ansii codes
	return replace(input, r"\e\[([A-Z]|[0-9])", "")
end

function get_input(question::Types.InfoQuestion)
	print("[Press Enter to continue]")
	input = getInput()
	# Remove ansii codes
	return replace(input, r"\e\[([A-Z]|[0-9])", "")
end

"""
Ask a question
"""
function ask(question)
	println(question.text)
end

function ask(question::Types.MultiQuestion)
	println(question.text)

	println("Options:")
	for (i, option) in enumerate(question.options)
		println(rpad(i, length(string(length(question.options)))), " - ", option)
	end
end

function ask(question::Types.FunctionQuestion)
	println(question.text)
	println("`!submit` to submit file and run tests")
	setup_function_file(question)
end

"""
Validate an answer to a question
"""
function validate(question::Types.InfoQuestion, response)
	return true
end

function validate(question::Types.SyntaxQuestion, response)
	return parse(response) == question.answer
end

function validate(question::Types.FunctionQuestion, response)
	if strip(response) != "!submit" return false end
	dir = joinpath(homedir(), "Juliet", "FunctionQuestion")
	file = joinpath(dir, filename(question))

	try
		inputs = [pair[1] for pair in question.tests]
		expected = [pair[2] for pair in question.tests]
		# Use readall instead of readlines because it gives an error on failure
		outputs = map(x -> readall(pipeline(`echo $x`, `julia $file`)), inputs)
		same = pair -> strip(pair[1]) == strip(pair[2])
		println("$(count(x -> x, map(same, zip(outputs, expected))))/$(length(inputs)) tests passed")
		return all(same, zip(outputs, expected))
	catch ex
		@show ex
		println("There were errors running your code")
		return false
	end
end

function validate(question::Types.MultiQuestion, response)
	return isa(parse(response), Number) && parse(Int, response) == question.answer
end

"""
Show an encouraging message and a hint
"""
function show_hint(question)
	println(rand([
		"Oops - that's not quite right",
		"Almost there - Keep trying!",
		"One more try",
		"Hang in there",
		"Missed it by that much",
		"Close, but no cigar"]))
	if length(question.hints) > 0
		println("hint: ", rand(question.hints))
	end
end

function show_hint(question::Types.FunctionQuestion)
	if length(question.hints) > 0
		println("hint: ", rand(question.hints))
	end
end

"""
Show a congratulatory message
"""
function show_congrats(question)
	println(rand([
		"You got it right!",
		"Great job!",
		"Keep up the great work!",
		"You're doing great!"]))
end

function show_congrats(question::Types.InfoQuestion) end

"""
Set up the file for a function question
"""
function setup_function_file(question::Types.FunctionQuestion)
	dir = joinpath(homedir(), "Juliet", "FunctionQuestion")
	mkpath(dir)

	file = joinpath(dir, filename(question))
	if !isfile(file)
		open(file, "w") do f
			write(f, question.template)
		end
	end

	try
	 	@compat @static if is_windows()
			Util.run(`explorer.exe $file`; whitelist=[1])
		elseif is_linux()
			run(`xdg-open $file`)
		elseif is_apple()
			try
				run(`open $file`)
			catch
				run(`open -a TextEdit $file`)
			end
		end
	catch
		println(STDERR, "Could not open file: please open `$file` manually")
	end
end

"""
Generate a filename for a function question
"""
function filename(question::Types.FunctionQuestion)
	description = x -> x[1:min(25, length(x))]
	return "$(description(question.text))-$(hash(question)).jl"
end

"""
Register a course with the current session of Juliet
"""
function register(course::Types.Course)
	if !in(course, courses)
		push!(courses, course)
	end
end

end # module
