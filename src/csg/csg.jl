"""
	ContextSensitiveGrammar <: Grammar

Represents a context-sensitive grammar.
Extends [`Grammar`](@ref) with constraints.

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
- `constraints::Vector{Constraint}`: A list of constraints that programs in this grammar have to abide.

Use the [`@csgrammar`](@ref) macro to create a [`ContextSensitiveGrammar`](@ref) object.
Use the [`@pcsgrammar`](@ref) macro to create a [`ContextSensitiveGrammar`](@ref) object with probabilities.
For context-free grammars, see [`ContextFreeGrammar`](@ref).
"""
mutable struct ContextSensitiveGrammar <: Grammar
	rules::Vector{Any}
	types::Vector{Union{Symbol, Nothing}}
	isterminal::BitVector
	iseval::BitVector
	bytype::Dict{Symbol, Vector{Int}}
	domains::Dict{Symbol,BitVector}    				
	childtypes::Vector{Vector{Symbol}}
	log_probabilities::Union{Vector{Real}, Nothing}
	constraints::Vector{Constraint}
end


"""
	expr2csgrammar(ex::Expr)::ContextSensitiveGrammar

A function for converting an `Expr` to a [`ContextSensitiveGrammar`](@ref).
If the expression is hardcoded, you should use the [`@csgrammar`](@ref) macro.
Only expressions in the correct format (see [`@csgrammar`](@ref)) can be converted.

### Example usage:

```@example
grammar = expr2csgrammar(
	begin
		R = x
		R = 1 | 2
		R = R + R
	end
)
```
"""
function expr2csgrammar(ex::Expr)::ContextSensitiveGrammar
	return cfg2csg(expr2cfgrammar(ex))
end



"""
	@csgrammar

A macro for defining a [`ContextSensitiveGrammar`](@ref). 
Constraints can be added afterwards using the [`addconstraint!`](@ref) function.

### Example usage:
```julia
grammar = @csgrammar begin
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

- [`@cfgrammar`](@ref) uses the same syntax to create [`ContextFreeGrammar`](@ref)s.
- [`@pcsgrammar`](@ref) uses a similar syntax to create probabilistic [`ContextSensitiveGrammar`](@ref)s.
"""
macro csgrammar(ex)
	return expr2csgrammar(ex)
end

"""
	cfg2csg(g::ContextFreeGrammar)::ContextSensitiveGrammar

Converts a [`ContextFreeGrammar`](@ref) to a [`ContextSensitiveGrammar`](@ref) without any [`Constraint`](@ref)s.
"""
function cfg2csg(g::ContextFreeGrammar)::ContextSensitiveGrammar
    return ContextSensitiveGrammar(
        g.rules, 
        g.types, 
        g.isterminal, 
        g.iseval, 
        g.bytype, 
		g.domains,
        g.childtypes, 
        g.log_probabilities, 
        []
    )
end

"""
	addconstraint!(grammar::ContextSensitiveGrammar, c::Constraint)

Adds a [`Constraint`](@ref) to a [`ContextSensitiveGrammar`](@ref).
"""
addconstraint!(grammar::ContextSensitiveGrammar, c::Constraint) = push!(grammar.constraints, c)

function Base.display(rulenode::RuleNode, grammar::ContextSensitiveGrammar)
	return rulenode2expr(rulenode, grammar)
end