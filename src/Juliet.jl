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
		return :(readline())
	end
end

storeDir = "$(Pkg.dir("Juliet"))/store"

help = Dict(
	"select" => """
	HELP:
		[Number]   -> select course
		`!back` -> exit course
		`!quit` -> exit Juliet
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
	# @show get_packaged(Types.Lesson)
	choose_lesson(get_packaged(Types.Lesson), get_packaged(Types.Course))
end

"""
Choose a lesson and complete it
"""
function choose_lesson(lessons, courses;
		currCourse::Union{Void, Types.Course}=nothing)
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
	while (print("> "); input = @getInput;
			!isa(parse(input), Number) ||
			!(0 < parse(Int, input) <= length(total)))
		if strip(input) == "!quit" return end
		if strip(input) == "!back" break end
		if strip(input) == "!help"
			println(help["select"])
			continue
		end
		println("Invalid selection")
	end

	if strip(input) == "!back"
		choose_lesson(get_packaged(Types.Lesson), get_packaged(Types.Course))
		return
	end
	selection = total[parse(Int, input)]
	if in(selection, lessons)
		complete_lesson(selection)
		if !isa(currCourse, Void) && selection != last(total)
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
			if strip(input) == "!skip"
				fire(fsm, "next")
				break
			end
			if strip(input) == "!quit"
				fire(fsm, "quit")
				break
			end
			if strip(input) == "!help"
				println(help["lesson"])
				continue
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

function get_input(question)
	print("> ")
	input = @getInput
	# Remove ansii codes
	return replace(input, r"\e\[([A-Z]|[0-9])", "")
end

function get_input(question::Types.InfoQuestion)
	print("...")
	input = @getInput
	# Remove ansii codes
	return replace(input, r"\e\[([A-Z]|[0-9])", "")
end

function ask(question)
	println(question.text)
end

function ask(question::Types.MultiQuestion)
	println(question.text)

	println("Options:")
	for (i, option) in enumerate(question.options)
		println(rpad(i, length(string(length(question.options)))),
			" - ", option)
	end
end

function ask(question::Types.FunctionQuestion)
	println(question.text)
	setup_function_file(lesson, question)
end

function validate(question::Types.InfoQuestion, response)
	return true
end

function validate(question::Types.SyntaxQuestion, response)
	return parse(response) == question.answer
end

function validate(question::Types.FunctionQuestion, response)
	if strip(response) != "!submit" return false end
	dir = normpath("$(homedir())/Juliet/$(question.lessonName)")
	file = normpath("$dir/$(question.index).jl")

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

function setup_function_file(question::Types.FunctionQuestion)
	dir = normpath("$(homedir())/Juliet")
	if !isdir(dir) mkdir(dir) end
	dir = normpath("$(homedir())/Juliet/$(question.lessonName)")
	if !isdir(dir) mkdir(dir) end

	file = normpath("$dir/$(question.index).jl")
	if !isfile(file)
		open(file, "w") do f
			write(f, question.template)
		end
	end

	@windows_only Util.run(`explorer.exe $file`; whitelist=[1])
	@linux_only run(`xdg-open $file`)
	@osx_only run(`open $file`)
end

end # module
