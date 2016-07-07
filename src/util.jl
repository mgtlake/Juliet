module Util

using Juliet
using JLD
using FileIO
using TOML

"""
Create a new lesson
"""
function new_lesson(name; description="", version=v"1", authors=[],
	keywords=[], questions=[])
	return Juliet.Types.Lesson(name, description, version, authors, keywords, questions)
end

"""
Add a question to a lesson
"""
function add_question!(lesson::Juliet.Types.Lesson,
		question::Juliet.Types.AbstractQuestion)
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
function add_lesson!(course::Juliet.Types.Course, lesson::Juliet.Types.Lesson)
	push!(course.lessons, lesson)
end

"""
Load from a JLD file
"""
function load_packaged(filename)
	return last(first(JLD.load(filename)))
end

function package_TOML(filename)
	package_lesson(Juliet.Convert.to_lesson(TOML.parse(readall(filename))))
end

"""
Package a lesson into the default location
"""
function package_lesson(lesson::Juliet.Types.Lesson)
	package_lesson(lesson, "$(Juliet.storeDir)/lessons/$(lesson.name).julietlesson")
end

"""
Package a lesson into a custom location
"""
function package_lesson(lesson::Juliet.Types.Lesson, filename)
	JLD.save(File(DataFormat{:JLD}, filename), lesson.name, lesson)
end

"""
Package a course into the default location
"""
function package_course(course::Juliet.Types.Course)
	package_course(course, "$storeDir/courses/$(course.name).julietcourse")
end

"""
Package a course into a custom location
"""
function package_course(course::Juliet.Types.Course, filename)
	JLD.save(File(DataFormat{:JLD}, filename), course.name, course)
end

"""
Reimplement half of process.jl because _some_ programs don't give nice
exit codes
"""
function run(cmds::Base.AbstractCmd, args...; whitelist=[])
    ps = Base.spawn(cmds, Base.spawn_opts_inherit(args...)...)
    success(ps; whitelist=whitelist) ? nothing : Base.pipeline_error(ps)
end

function test_success(proc::Base.Process; whitelist=[])
	assert(Base.process_exited(proc))
	if proc.exitcode < 0
		#TODO: this codepath is not currently tested
		throw(Base.UVError("could not start process $(string(proc.cmd))", proc.exitcode))
	end
	(proc.exitcode == 0 || proc.exitcode in whitelist) &&
		(proc.termsignal == 0 || proc.termsignal == Base.SIGPIPE
		|| proc.termsignal in whitelist)
end

function success(x::Base.Process; whitelist=[])
	Base.wait(x)
	Base.kill(x)
	test_success(x; whitelist=whitelist)
end
success(procs::Base.Vector{Base.Process}; whitelist=[]) =
	mapreduce(success, &, procs; whitelist=whitelist)
success(procs::Base.ProcessChain; whitelist=[]) =
	success(procs.processes; whitelist=whitelist)
success(cmd::Base.AbstractCmd; whitelist=[]) =
	success(Base.spawn(cmd); whitelist=whitelist)

end # module
