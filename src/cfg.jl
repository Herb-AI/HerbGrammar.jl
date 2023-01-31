"""
Grammar
Represents a grammar and its production rules.
Use the @grammar macro to create a Grammar object.
"""
mutable struct ContextFreeGrammar <: Grammar
	rules::Vector{Any}    # list of RHS of rules (subexpressions)
	types::Vector{Symbol} # list of LHS of rules (types, all symbols)
	isterminal::BitVector # whether rule i is terminal
	iseval::BitVector     # whether rule i is an eval rule
	bytype::Dict{Symbol,Vector{Int}}   # maps type to all rules of said type
	childtypes::Vector{Vector{Symbol}} # list of types of the children for each rule. Empty if terminal
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
	return ContextFreeGrammar(rules, types, is_terminal, is_eval, bytype, childtypes)
end

"""
@cfgrammar
Define a grammar and return it as a Grammar. For example:
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
		ex.args[2:end]                      #a|b|c case
		for t in terms
			_parse_rule!(v, t)
		end
	else
		push!(v, ex)
	end
end

function Base.display(rulenode::RuleNode, grammar::ContextFreeGrammar)
	return rulenode2expr(rulenode, grammar)
end


"""
Adds a rule to the grammar. 
If a rule is already in the grammar, it is ignored.
Usage: 
```
	add_rule!(grammar, :("Real = Real + Real"))
```
The syntax is identical to the syntax of @csgrammar, but only single rules are supported.
"""
function add_rule!(cfgrammar :: ContextFreeGrammar, e::Expr)
	if e.head == :(=)
		s = e.args[1]		# Name of return type
		rule = e.args[2]	# expression?
		rvec = Any[]
		_parse_rule!(rvec, rule)
		for r ∈ rvec
			if r ∈ cfgrammar.rules
				continue
			end
			push!(cfgrammar.rules, r)
			push!(cfgrammar.iseval, iseval(rule))
			push!(cfgrammar.types, s)
			cfgrammar.bytype[s] = push!(get(cfgrammar.bytype, s, Int[]), length(cfgrammar.rules))
		end
	end
	alltypes = collect(keys(cfgrammar.bytype))

	# is_terminal and childtypes need to be recalculated from scratch, since a new type might 
	# be added that was used as a terminal symbol before.
	cfgrammar.isterminal = [isterminal(rule, alltypes) for rule ∈ cfgrammar.rules]
	cfgrammar.childtypes = [get_childtypes(rule, alltypes) for rule ∈ cfgrammar.rules]
end
