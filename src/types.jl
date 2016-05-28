module Types

export Lesson

abstract AbstractQuestion

type Lesson
	name::AbstractString
	description::AbstractString
	version::VersionNumber
	authors::Array{AbstractString, 1}
	keywords::Array{AbstractString, 1}
	questions::Array{AbstractQuestion, 1}
end

type InfoQuestion <: AbstractQuestion
	text::AbstractString
end

type SyntaxQuestion <: AbstractQuestion
	text::AbstractString
	hints::Array{AbstractString, 1}
	answer::Expr
end

type FunctionQuestion <: AbstractQuestion
	text::AbstractString
	hints::Array{AbstractString, 1}
	tests::Function
end

type MultiQuestion <: AbstractQuestion
	text::AbstractString
	hints::Array{AbstractString, 1}
	options::Array{AbstractString, 1}
	answer::Int
end

end  # module
