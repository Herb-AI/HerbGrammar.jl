"""
Represents a context-free grammar and its production rules.
Use the @cfgrammar macro to create a ContextFreeGrammar object.
Use the @pcfgrammar macro to create a ContextFreeGrammar object with probabilities.
"""
mutable struct ContextFreeGrammar <: Grammar
	rules::Vector{Any}    							# list of RHS of rules (subexpressions)
	types::Vector{Union{Symbol, Nothing}} 			# list of LHS of rules (types, all symbols)
	isterminal::BitVector 							# whether rule i is terminal
	iseval::BitVector     							# whether rule i is an eval rule
	bytype::Dict{Symbol,Vector{Int}}   				# maps type to all rules of said type
	childtypes::Vector{Vector{Symbol}} 				# list of types of the children for each rule. Empty if terminal
	probabilities::Union{Vector{Real}, Nothing} 	# list of probabilities for the rules if this is a probabilistic grammar
end

"""
Function for converting an `Expr` to a `ContextFreeGrammar`. 
If the expression is hardcoded, you should use the `@cfgrammar` macro.
Only expressions in the correct format can be converted.
"""
function expr2cfgrammar(ex::Expr)::ContextFreeGrammar
	rules = Any[]
	types = Symbol[]
	bytype = Dict{Symbol,Vector{Int}}()
	for e ∈ ex.args
		if isa(e, Expr)
			if e.head == :(=)
				s = e.args[1] 		# name of return type
				rule = e.args[2] 	# expression?
				rvec = Any[]
				_parse_rule!(rvec, rule)
				for r ∈ rvec
					push!(rules, r)
					push!(types, s)
					bytype[s] = push!(get(bytype, s, Int[]), length(rules))
				end
			end
		end
	end
	alltypes = collect(keys(bytype))
	is_terminal = [isterminal(rule, alltypes) for rule ∈ rules]
	is_eval = [iseval(rule) for rule ∈ rules]
	childtypes = [get_childtypes(rule, alltypes) for rule ∈ rules]
	return ContextFreeGrammar(rules, types, is_terminal, is_eval, bytype, childtypes, nothing)
end

"""
@cfgrammar
Define a grammar and return it as a ContextFreeGrammar. 
Syntax is identical to @csgrammar.
For example:
```julia-repl
grammar = @cfgrammar begin
R = x
R = 1 | 2
R = R + R
end
```
"""
macro cfgrammar(ex)
	return expr2cfgrammar(ex)
end

_parse_rule!(v::Vector{Any}, r) = push!(v, r)

function _parse_rule!(v::Vector{Any}, ex::Expr)
	if ex.head == :call && ex.args[1] == :|
		terms = length(ex.args) == 2 ?
		collect(eval(ex.args[2])) :    #|(a:c) case
		ex.args[2:end]                 #a|b|c case
		for t in terms
			_parse_rule!(v, t)
		end
	else
		push!(v, ex)
	end
end
