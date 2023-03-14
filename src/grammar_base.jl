"""
Returns true if the rule is terminal, ie does not contain any of the types in the provided vector.
For example, :(x) is terminal, and :(1+1) is terminal, but :(Real + Real) is typically not.
"""
function isterminal(rule::Any, types::AbstractVector{Symbol})
    if isa(rule, Expr)
        for arg ∈ rule.args
            if !isterminal(arg, types)
                return false
            end
        end
    end
    return rule ∉ types
end


"""
Returns true if the rule is the special evaluate immediately function, i.e., _()
"""
iseval(rule) = false
iseval(rule::Expr) = (rule.head == :call && rule.args[1] == :_)


"""
Returns the child types of a production rule.
"""
function get_childtypes(rule::Any, types::AbstractVector{Symbol})
    retval = Symbol[]
    if isa(rule, Expr)
        for arg ∈ rule.args
            append!(retval, get_childtypes(arg, types))
        end
    elseif rule ∈ types
        push!(retval, rule)
    end
    return retval
end

"""
Represents all grammars.
The library assumes that the grammar structs have at least the following attributes:
rules::Vector{Any}    # list of RHS of rules (subexpressions)
types::Vector{Symbol} # list of LHS of rules (types, all symbols)
isterminal::BitVector # whether rule i is terminal
iseval::BitVector     # whether rule i is an eval rule
bytype::Dict{Symbol,Vector{Int}}   # maps type to all rules of said type
domains::Dict{Symbol,BitVector}    # maps type to a domain bitvector
childtypes::Vector{Vector{Symbol}} # list of types of the children for each rule. Empty if terminal
probabilities::Union{Vector{Real}, Nothing} # List of probabilities for each rule. Nothing if grammar is non-probabilistic
"""
abstract type Grammar end

Base.getindex(grammar::Grammar, typ::Symbol) = grammar.bytype[typ]


"""
Appends the production rules of grammar2 to grammar1.
"""
function Base.append!(grammar1::Grammar, grammar2::Grammar)
    N = length(grammar1.rules)
    append!(grammar1.rules, grammar2.rules)
    append!(grammar1.types, grammar2.types)
    append!(grammar1.isterminal, grammar2.isterminal)
    append!(grammar1.iseval, grammar2.iseval)
    append!(grammar1.childtypes, copy.(grammar2.childtypes))
    for (s,v) in grammar2.bytype
        grammar1.bytype[s] = append!(get(grammar1.bytype, s, Int[]), N .+ v)
    end
    grammar1
end


"""
Returns a list of nonterminals in the grammar.
"""
nonterminals(grammar::Grammar) = collect(keys(grammar.bytype))


"""
Returns the type of the production rule at rule_index.
"""
return_type(grammar::Grammar, rule_index::Int) = grammar.types[rule_index]


"""
Returns the types of the children (nonterminals) of the production rule at rule_index.
"""
child_types(grammar::Grammar, rule_index::Int) = grammar.childtypes[rule_index]


"""
Returns the domain for the hole of a certain type.
"""
get_domain(g::Grammar, type::Symbol)::BitVector = deepcopy(g.domains[type])

"""
Returns the domain bitvector for a domain defined as rule index vector.
"""
get_domain(g::Grammar, rules::Vector{Int})::BitVector = BitArray(r ∈ rules for r ∈ 1:length(g.rules))

"""
Returns true if the production rule at rule_index is terminal, i.e., does not contain any nonterminal symbols.
"""
isterminal(grammar::Grammar, rule_index::Int) = grammar.isterminal[rule_index]


"""
Returns true if any production rules in grammar contain the special _() eval function.
"""
iseval(grammar::Grammar) = any(grammar.iseval)


"""
Returns true if the production rule at rule_index contains the special _() eval function.
"""
iseval(grammar::Grammar, index::Int) = grammar.iseval[index]


"""
Return the log probability for a rule in the grammar.
"""
function log_probability(grammar::Grammar, index::Int)::Real
	if !isprobabilistic(grammar)
		@warn "Requesting probability in a non-probabilistic grammar.\nUniform distribution is assumed."
		# Assume uniform probability
		return log(1 / length(grammar.bytype[grammar.types[index]]))
	end
	return grammar.log_probabilities[index]
end

"""
Return the probability for a rule in the grammar.
Use `log_probability` whenever possible.
"""
function probability(grammar::Grammar, index::Int)::Real
	if !isprobabilistic(grammar)
		@warn "Requesting probability in a non-probabilistic grammar.\nUniform distribution is assumed."
		# Assume uniform probability
		return 1 / length(grammar.bytype[grammar.types[index]])
	end
	return ℯ^grammar.log_probabilities[index]
end

"""
Function for checking if a grammar is probabilistic.
"""
isprobabilistic(grammar::Grammar) = !(grammar.log_probabilities ≡ nothing)


"""
Returns the number of children (nonterminals) of the production rule at rule_index.
"""
nchildren(grammar::Grammar, rule_index::Int) = length(grammar.childtypes[rule_index])


"""
Returns the maximum arity (number of children) over all production rules in the grammar.
"""
max_arity(grammar::Grammar) = maximum(length(cs) for cs in grammar.childtypes)


function Base.show(io::IO, grammar::Grammar)
	for i in eachindex(grammar.rules)
	    println(io, i, ": ", grammar.types[i], " = ", grammar.rules[i])
	end
end


"""
Adds a rule to the grammar. 
If a rule is already in the grammar, it is ignored.
Usage: 
```
	add_rule!(grammar, :("Real = Real + Real"))
```
The syntax is identical to the syntax of @csgrammar/@cfgrammar, but only single rules are supported.
"""
function add_rule!(g::Grammar, e::Expr)
	if e.head == :(=)
		s = e.args[1]		# Name of return type
		rule = e.args[2]	# expression?
		rvec = Any[]
		_parse_rule!(rvec, rule)
		for r ∈ rvec
			if r ∈ g.rules
				continue
			end
			push!(g.rules, r)
			push!(g.iseval, iseval(rule))
			push!(g.types, s)
			g.bytype[s] = push!(get(g.bytype, s, Int[]), length(g.rules))
		end
	end
	alltypes = collect(keys(g.bytype))

	# is_terminal and childtypes need to be recalculated from scratch, since a new type might 
	# be added that was used as a terminal symbol before.
	g.isterminal = [isterminal(rule, alltypes) for rule ∈ g.rules]
	g.childtypes = [get_childtypes(rule, alltypes) for rule ∈ g.rules]
	g.domains = Dict(type => BitArray(r ∈ g.bytype[type] for r ∈ 1:length(g.rules)) for type ∈ keys(g.bytype))
	return g
end


"""
Removes the rule corresponding to `idx` from the grammar. 
In order to avoid shifting indices, the rule is replaced with `nothing`,
and all other data structures are updated accordingly.
"""
function remove_rule!(g::Grammar, idx::Int)
	type = g.types[idx]
	g.rules[idx] = nothing
	g.iseval[idx] = false
	g.types[idx] = nothing
	deleteat!(g.bytype[type], findall(isequal(idx), g.bytype[type]))
	if length(g.bytype[type]) == 0
		# remove type
		delete!(g.bytype, type)
		alltypes = collect(keys(g.bytype))
		g.isterminal = [isterminal(rule, alltypes) for rule ∈ g.rules]
		g.childtypes = [get_childtypes(rule, alltypes) for rule ∈ g.rules]
	end
	for domain ∈ values(g.domains)
		domain[idx] = 0
	end
	return g
end


"""
Removes any placeholders for previously deleted rules. 
This means that indices get shifted.
"""
function cleanup_removed_rules!(g::Grammar)
	rules_to_cleanup = findall(isequal(nothing), g.rules)
	# highest indices are removed first, otherwise their index will have shifted
	for v ∈ [g.rules, g.types, g.isterminal, g.iseval, g.childtypes]
		deleteat!(v, rules_to_cleanup)
	end
	# update bytype
	empty!(g.bytype)

	for (idx, type) ∈ enumerate(g.types)
		g.bytype[type] = push!(get(g.bytype, type, Int[]), idx)
	end
	g.domains = Dict(type => BitArray(r ∈ g.bytype[type] for r ∈ 1:length(g.rules)) for type ∈ keys(g.bytype))
	return g
end