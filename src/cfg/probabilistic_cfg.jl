"""
Function for converting an `Expr` to a [`ContextFreeGrammar`](@ref) with probabilities.
If the expression is hardcoded, you should use the `@pcfgrammar` macro.
Only expressions in the correct format (see [`@pcfgrammar`](@ref)) can be converted.

### Example usage:
	
```@example
grammar = expr2pcsgrammar(
	begin
		0.5 : R = x
		0.3 : R = 1 | 2
		0.2 : R = R + R
	end
)
```
"""
function expr2pcfgrammar(ex::Expr)::ContextFreeGrammar
	rules = Any[]
	types = Symbol[]
	probabilities = Real[]
	bytype = Dict{Symbol,Vector{Int}}()
	for e ∈ ex.args
		if e isa Expr
			if e.head == :(=)
				left = e.args[1] 		# name of return type and probability
				if left isa Expr && left.head == :call && left.args[1] == :(:)
					p = left.args[2] 			# Probability
					s = left.args[3]			# Return type
					rule = e.args[2].args[2] 	# extract rule from block expr

					rvec = Any[]
					_parse_rule!(rvec, rule)
					for r ∈ rvec
						push!(rules, r)
						push!(types, s)
						# Divide the probability of this line by the number of rules it defines. 
						push!(probabilities, p / length(rvec))
						bytype[s] = push!(get(bytype, s, Int[]), length(rules))
					end
				else
					@error "Rule without probability encountered in probabilistic grammar. Rule ignored."
				end
			end
		end
	end
	alltypes = collect(keys(bytype))
	# Normalize probabilities for each type
	for t ∈ alltypes
		total_prob = sum(probabilities[i] for i ∈ bytype[t])
		if !(total_prob ≈ 1)
			@warn "The probabilities for type $t don't add up to 1, so they will be normalized."
			for i ∈ bytype[t]
				probabilities[i] /= total_prob
			end
		end
	end

	log_probabilities = [log(x) for x ∈ probabilities]
	is_terminal = [isterminal(rule, alltypes) for rule in rules]
	is_eval = [iseval(rule) for rule in rules]
	childtypes = [get_childtypes(rule, alltypes) for rule in rules]
	domains = Dict(type => BitArray(r ∈ bytype[type] for r ∈ 1:length(rules)) for type ∈ alltypes)
	return ContextFreeGrammar(rules, types, is_terminal, is_eval, bytype, domains, childtypes, log_probabilities)
end


"""
	@pcfgrammar

A macro for defining a probabilistic [`ContextFreeGrammar`](@ref). 

### Example usage:
```julia
grammar = @pcfgrammar begin
	0.5 : R = x
	0.3 : R = 1 | 2
	0.2 : R = R + R
end
```

### Syntax:

The syntax of rules is identical to the syntax used by [`@cfgrammar`](@ref):

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

Every rule is also prefixed with a probability.
Rules and probabilities are separated using the `:` symbol.
If multiple rules are defined on a single line, the probability is equally divided between the rules.
The sum of probabilities for all rules of a certain non-terminal symbol should be equal to 1. 
The probabilities are automatically scaled if this isn't the case.


### Related:

- [`@pcsgrammar`](@ref) uses the same syntax to create probabilistic [`ContextSensitiveGrammar`](@ref)s.
- [`@cfgrammar`](@ref) uses a similar syntax to create non-probabilistic [`ContextFreeGrammar`](@ref)s.
"""
macro pcfgrammar(ex)
	return expr2pcfgrammar(ex)
end