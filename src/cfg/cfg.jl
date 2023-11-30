"""
	ContextFreeGrammar <: Grammar

Represents a context-free grammar and its production rules.
Consists of:

- `rules::Vector{Any}`: A list of RHS of rules (subexpressions).
- `types::Vector{Symbol}`: A list of LHS of rules (types, all symbols).
- `isterminal::BitVector`: A bitvector where bit `i` represents whether rule `i` is terminal.
- `iseval::BitVector`: A bitvector where bit `i` represents whether rule i is an eval rule.
- `bytype::Dict{Symbol,Vector{Int}}`: A dictionary that maps a type to all rules of said type.
- `domains::Dict{Symbol, BitVector}`: A dictionary that maps a type to a domain bitvector. 
  The domain bitvector has bit `i` set to true iff the `i`th rule is of this type.
- `childtypes::Vector{Vector{Symbol}}`: A list of types of the children for each rule. 
  If a rule is terminal, the corresponding list is empty.
- `log_probabilities::Union{Vector{Real}, Nothing}`: A list of probabilities for each rule. 
  If the grammar is non-probabilistic, the list can be `nothing`.

Use the [`@cfgrammar`](@ref) macro to create a [`ContextFreeGrammar`](@ref) object.
Use the [`@pcfgrammar`](@ref) macro to create a [`ContextFreeGrammar`](@ref) object with probabilities.
For context-sensitive grammars, see [`ContextSensitiveGrammar`](@ref).

"""
mutable struct ContextFreeGrammar <: Grammar
	rules::Vector{Any}    							# list of RHS of rules (subexpressions)
	types::Vector{Union{Symbol, Nothing}} 			# list of LHS of rules (types, all symbols)
	isterminal::BitVector 							# whether rule i is terminal
	iseval::BitVector     							# whether rule i is an eval rule
	bytype::Dict{Symbol,Vector{Int}}   				# maps type to all rules of said type
	domains::Dict{Symbol,BitVector}					# maps type to a domain bitvector
	childtypes::Vector{Vector{Symbol}} 				# list of types of the children for each rule. Empty if terminal
	log_probabilities::Union{Vector{Real}, Nothing} # list of probabilities for the rules if this is a probabilistic grammar
end

"""
	expr2cfgrammar(ex::Expr)::ContextFreeGrammar

A function for converting an `Expr` to a [`ContextFreeGrammar`](@ref).
If the expression is hardcoded, you should use the [`@cfgrammar`](@ref) macro.
Only expressions in the correct format (see [`@cfgrammar`](@ref)) can be converted.

### Example usage:

```@example
grammar = expr2cfgrammar(
	begin
		R = x
		R = 1 | 2
		R = R + R
	end
)
```
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
				parse_rule!(rvec, rule)
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
	domains = Dict(type => BitArray(r ∈ bytype[type] for r ∈ 1:length(rules)) for type ∈ alltypes)
	return ContextFreeGrammar(rules, types, is_terminal, is_eval, bytype, domains, childtypes, nothing)
end

"""
	@cfgrammar

A macro for defining a [`ContextFreeGrammar`](@ref). 

### Example usage:
```julia
grammar = @cfgrammar begin
	R = x
	R = 1 | 2
	R = R + R
end
```

### Syntax:

- Literals: Symbols that are already defined in Julia are considered literals, such as `1`, `2`, or `π`.
  For example: `R = 1`.
- Variables: A variable is a symbol that is not a nonterminal symbol and not already defined in Julia.
  For example: `R = x`.
- Functions: Functions and infix operators that are defined in Julia or the `Main` module can be used 
  with the default evaluator. For example: `R = R + R`, `R = f(a, b)`.
- Combinations: Multiple rules can be defined on a single line in the grammar definition using the `|` symbol.
  For example: `R = 1 | 2 | 3`.
- Iterators: Another way to define multiple rules is by providing a Julia iterator after a `|` symbol.
  For example: `R = |(1:9)`.

### Related:

- [`@csgrammar`](@ref) uses the same syntax to create [`ContextSensitiveGrammar`](@ref)s.
- [`@pcfgrammar`](@ref) uses a similar syntax to create probabilistic [`ContextFreeGrammar`](@ref)s.
"""
macro cfgrammar(ex)
	return expr2cfgrammar(ex)
end

parse_rule!(v::Vector{Any}, r) = push!(v, r)

function parse_rule!(v::Vector{Any}, ex::Expr)
    if ex.head == :call && ex.args[1] == :|
        if length(ex.args) == 2 && ex.args[2].args[1] == :(:)
            terms = collect(ex.args[2].args[2]:ex.args[2].args[3])  #|(a:c) case
        elseif length(ex.args) == 2 && ex.args[2].args[1] != :(:)
            terms = eval(ex.args[2])  # :([1,2,3]) case
        else
            terms = ex.args[2:end]  #a|b|c case
        end
        for t in terms
            parse_rule!(v, t)
        end
    else
        push!(v, ex)
    end
end
