"""
Represents a context-sensitive grammar constraint.
Implementations can be found in the Herb-AI/Constraints.jl repository.
"""
abstract type Constraint end

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
	probabilities::Union{Vector{Real}, Nothing}
	constraints::Vector{Constraint}
end


"""
Function for converting an `Expr` to a `ContextSensitiveGrammar`.
If the expression is hardcoded, you should use the `@csgrammar` macro.
Only expressions in the correct format can be converted.
"""
function expr2csgrammar(ex::Expr)::ContextSensitiveGrammar
	return cfg2csg(expr2cfgrammar(ex))
end


"""
@csgrammar
Define a grammar and return it as a ContextSensitiveGrammar. 
Syntax is identical to @cfgrammar.
For example:
```julia-repl
grammar = @csgrammar begin
R = x
R = 1 | 2
R = R + R
end
```
"""
macro csgrammar(ex)
	return expr2csgrammar(ex)
end


"""
Converts a ContextFreeGrammar to a ContextSensitiveGrammar without any constraints.
"""
function cfg2csg(g::ContextFreeGrammar)::ContextSensitiveGrammar
    return ContextSensitiveGrammar(
        g.rules, 
        g.types, 
        g.isterminal, 
        g.iseval, 
        g.bytype, 
        g.childtypes, 
        g.probabilities, 
        []
    )
end


"""
Add constraint to the grammar
"""
addconstraint!(grammar::ContextSensitiveGrammar, cons::Constraint) = push!(grammar.constraints, cons)

function Base.display(rulenode::RuleNode, grammar::ContextSensitiveGrammar)
	return rulenode2expr(rulenode, grammar)
end
