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

end # module
