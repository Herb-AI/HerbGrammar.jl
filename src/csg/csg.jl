"""
	Structure representing context-sensitive grammar
	Extends ExprRules.Grammar with constraints
"""
struct ContextSensitiveGrammar <: Grammar
	rules::Vector{Any}
	types::Vector{Union{Symbol, Nothing}}
	isterminal::BitVector
	iseval::BitVector
	bytype::Dict{Symbol, Vector{Int}}
	childtypes::Vector{Vector{Symbol}}
	constraints::Vector{Constraint}
end

"""
Function for converting an `Expr` to a `ContextSensitiveGrammar`.
If the expression is hardcoded, you should use the `@csgrammar` macro.
Only expressions in the correct format can be converted.
"""
function expr2csgrammar(ex::Expr)::ContextSensitiveGrammar
	rules = Any[]
	types = Symbol[]
	bytype = Dict{Symbol,Vector{Int}}()
	for e ∈ ex.args
	    if e isa Expr
			if e.head == :(=)
				s = e.args[1] 		# name of return type
				rule = e.args[2] 	# expression?
				rvec = Any[]
				_parse_rule!(rvec, rule)
				for r in rvec
					push!(rules, r)
					push!(types, s)
					bytype[s] = push!(get(bytype, s, Int[]), length(rules))
				end
			end
	    end
	end
	alltypes = collect(keys(bytype))
	is_terminal = [isterminal(rule, alltypes) for rule in rules]
	is_eval = [iseval(rule) for rule in rules]
	childtypes = [get_childtypes(rule, alltypes) for rule in rules]
	return ContextSensitiveGrammar(rules, types, is_terminal, is_eval, bytype, childtypes, [])
end

macro csgrammar(ex)
	return expr2csgrammar(ex)
end


"""
Add constraint to the grammar
"""
addconstraint!(grammar::ContextSensitiveGrammar, cons::Constraint) = push!(grammar.constraints, cons)

function Base.display(rulenode::RuleNode, grammar::ContextSensitiveGrammar)
	return rulenode2expr(rulenode, grammar)
end
