module Convert

using Juliet
using Match

function to_lesson(dict::Dict)
	dict = lowercase(dict)
	lesson = Juliet.new_lesson(dict["name"])
	if "description" in keys(dict) lesson.description = dict["description"] end
	if "version" in keys(dict)
		lesson.authors = convert(VersionNumber, dict["version"])
	end
	if "authors" in keys(dict) lesson.authors = dict["authors"] end
	if "keywords" in keys(dict) lesson.keywords = dict["keywords"] end

	for question in dict["questions"]
		Juliet.add_question!(lesson, match_question(question))
	end

	return lesson
end

function match_question(question)
	@match Base.lowercase(question["type"]) begin
		"infoquestion" => Juliet.Types.InfoQuestion(question["text"])
		"syntaxquestion" => Juliet.Types.SyntaxQuestion(question["text"],
			question["hints"], parse(question["answer"]))
		"functionquestion" => Juliet.Types.FunctionQuestion(question("text"),
			question["hints"], question["test"])
		"multiquestion" => Juliet.Types.MultiQuestion(question["text"],
			question["hints"], question["options"], question["answer"])
	end
end

function lowercase(dict::Dict)
	newdict = Dict{AbstractString, Any}()
	for pair in dict
		key = Base.lowercase(first(pair))
		value = last(pair)
		if isa(value, Dict{AbstractString, Any})
			value = lowercase(value)
		end
		newdict[key] = value
	end
	return newdict
end

end # module
