module Types

export Lesson

abstract AbstractQuestion

type Lesson
	name::AbstractString
	description::AbstractString
	version::VersionNumber
	authors::Vector{AbstractString}
	keywords::Vector{AbstractString}
	questions::Vector{AbstractQuestion}
end

immutable InfoQuestion <: AbstractQuestion
	text::AbstractString
end

immutable SyntaxQuestion <: AbstractQuestion
	text::AbstractString
	hints::Vector{AbstractString}
	answer::Expr
end

immutable FunctionQuestion <: AbstractQuestion
	text::AbstractString
	hints::Vector{AbstractString}
	# I'd like to use a tuple, but most formats don't support it so I'll
	# use an array for now
	tests::Vector{Vector{AbstractString}}
	template::AbstractString
end

immutable MultiQuestion <: AbstractQuestion
	text::AbstractString
	hints::Vector{AbstractString}
	options::Vector{AbstractString}
	answer::Int
end

type Course
	name::AbstractString
	description::AbstractString
	version::VersionNumber
	authors::Vector{AbstractString}
	keywords::Vector{AbstractString}
	lessons::Vector{Lesson}
end

end  # module
