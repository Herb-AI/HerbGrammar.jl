
"""
Function for converting an `Expr` to a `ContextFreeGrammar` with probabilities.
If the expression is hardcoded, you should use the `@pcfgrammar` macro.
Only expressions in the correct format can be converted.
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
Define a probabilistic grammar and return it as a ContextFreeGrammar. 
Syntax is identical to @pcsgrammar.
For example:
```julia-repl
grammar = @pcfgrammar begin
0.5 : R = x
0.3 : R = 1 | 2
0.2 : R = R + R
end
```
"""
macro pcfgrammar(ex)
	return expr2pcfgrammar(ex)
end