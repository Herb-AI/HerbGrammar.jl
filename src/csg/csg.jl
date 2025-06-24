"""
	ContextSensitiveGrammar <: AbstractGrammar

Represents a context-sensitive grammar.
Extends [`AbstractGrammar`](@ref) with constraints.

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
- `bychildtypes::Vector{BitVector}`: A bitvector of rules that share the same childtypes for each rule
- `log_probabilities::Union{Vector{Real}, Nothing}`: A list of probabilities for each rule. 
  If the grammar is non-probabilistic, the list can be `nothing`.
- `constraints::Vector{AbstractConstraint}`: A list of constraints that programs in this grammar have to abide.

Use the [`@csgrammar`](@ref) macro to create a [`ContextSensitiveGrammar`](@ref) object.
Use the [`@pcsgrammar`](@ref) macro to create a [`ContextSensitiveGrammar`](@ref) object with probabilities.
"""
mutable struct ContextSensitiveGrammar <: AbstractGrammar
    rules::Vector{Any}
    types::Vector{Union{Symbol,Nothing}}
    isterminal::BitVector
    iseval::BitVector
    bytype::Dict{Symbol,Vector{Int}}
    domains::Dict{Symbol,BitVector}
    childtypes::Vector{Vector{Symbol}}
    bychildtypes::Vector{BitVector}
    log_probabilities::Union{Vector{Real},Nothing}
    constraints::Vector{AbstractConstraint}
end

ContextSensitiveGrammar(
    rules::Vector{<:Any},
    types::Vector{<:Union{Symbol,Nothing}},
    isterminal::Union{BitVector,Vector{Bool}},
    iseval::Union{BitVector,Vector{Bool}},
    bytype::Dict{Symbol,Vector{Int}},
    domains::Dict{Symbol,BitVector},
    childtypes::Vector{Vector{Symbol}},
    bychildtypes::Vector{BitVector},
    log_probabilities::Union{Vector{<:Real},Nothing}
) = ContextSensitiveGrammar(rules, types, isterminal, iseval, bytype, domains, childtypes, bychildtypes, log_probabilities, AbstractConstraint[])

ContextSensitiveGrammar() = ContextSensitiveGrammar([], [], BitVector[], BitVector[], Dict{Symbol,Vector{Int}}(), Dict{Symbol,BitVector}(), Vector{Vector{Symbol}}(), Vector{BitVector}(), nothing, AbstractConstraint[])

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
    grammar = ContextSensitiveGrammar()

    for e ∈ ex.args
        if isa(e, Expr)
            add_rule!(grammar, e)
        end
    end

    return grammar
end



"""
	@csgrammar

A macro for defining a [`ContextSensitiveGrammar`](@ref). 
AbstractConstraints can be added afterwards using the [`addconstraint!`](@ref) function.

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

- [`@pcsgrammar`](@ref) uses a similar syntax to create probabilistic [`ContextSensitiveGrammar`](@ref)s.
"""
macro csgrammar(ex)
    return :(expr2csgrammar($(QuoteNode(ex))))
end


"""
	@cfgrammar

This macro is deprecated and will be removed in future versions. Use [`@csgrammar`](@ref) instead.
"""
macro cfgrammar(ex)
    return :(expr2csgrammar($(QuoteNode(ex))))
end

parse_rule!(v::Vector{Any}, r) = push!(v, r)

function parse_rule!(v::Vector{Any}, ex::Expr)
    # Strips `LineNumberNode`s from the expression
    Base.remove_linenums!(ex)

    if ex.head == :call && ex.args[1] == :|
        terms = _expand_shorthand(ex.args)

        for t in terms
            parse_rule!(v, t)
        end
    else
        push!(v, ex)
    end
end

function _expand_shorthand(args::Vector{Any})
    # expand a rule using the `|` symbol:
    # `X = |(1:3)`, `X = 1|2|3`, `X = |([1,2,3])`
    # these should all be equivalent and should expand to
    # the following 3 rules: `X = 1`, `X = 2`, and `X = 3`
    if args[1] != :|
        throw(ArgumentError("Tried to parse: $ex as a shorthand rule, but it is not a shorthand rule."))
    end

    if length(args) == 2
        to_expand = args[2]
        if to_expand.args[1] == :(:)
            expanded = collect(to_expand.args[2]:to_expand.args[3])# (1:3) case
        else
            expanded = to_expand.args# ([1,2,3]) case
        end
    elseif length(args) == 3
        expanded = args[2:end]# 1|2|3 case
    else
        throw(ArgumentError("Failed to parse shorthand for rule: $ex"))
    end
end

"""
	addconstraint!(grammar::ContextSensitiveGrammar, c::AbstractConstraint)

Adds a [`AbstractConstraint`](@ref) to a [`ContextSensitiveGrammar`](@ref). Errors if constraint's domain is not valid.
"""
function addconstraint!(grammar::ContextSensitiveGrammar, c::AbstractConstraint)
    if !HerbCore.is_domain_valid(c, grammar)
        error("The domain of $(typeof(c)) is not valid for the provided grammar.")
    end
    push!(grammar.constraints, c)
end

"""
Clear all constraints from the grammar
"""
clearconstraints!(grammar::ContextSensitiveGrammar) = empty!(grammar.constraints)

function Base.display(rulenode::RuleNode, grammar::ContextSensitiveGrammar)
    return rulenode2expr(rulenode, grammar)
end

"""
	merge_grammars!(merge_to::AbstractGrammar, merge_from::AbstractGrammar)

Adds all rules and constraints from `merge_from` to `merge_to`. Duplicate rules are ignored.
"""
function merge_grammars!(merge_to::AbstractGrammar, merge_from::AbstractGrammar)
    mapping = Dict{Integer,Integer}() # keep track of new rule indices for merge_from grammar
    # Dict for easy lookup of duplicate rules 
    rule_to_index = Dict{Tuple,Int}()
    for (idx, (type, rule)) in enumerate(zip(merge_to.types, merge_to.rules))
        rule_to_index[(type, rule)] = idx
    end

    # add rules
    for i in eachindex(merge_from.rules)
        n_rules_before = length(merge_to.rules)
        expression = :($(merge_from.types[i]) = $(merge_from.rules[i]))
        add_rule!(merge_to, expression)
        n_rules_after = length(merge_to.rules)
        if n_rules_before < n_rules_after
            mapping[i] = n_rules_after
        else
            # If rule already exists, rule index from merge_to grammar is used for mapping.  
            idx = rule_to_index[(merge_from.types[i], merge_from.rules[i])]
            mapping[i] = idx
        end
    end
    # update constraints of ...
    # ... `merge_to` grammar
    for i in eachindex(merge_to.constraints)
        HerbCore.update_rule_indices!(merge_to.constraints[i], length(merge_to.rules))
    end

    # ... `merge_from` grammar (mapping required)
    from_constraints = deepcopy(merge_from.constraints) # we don't want to modify `merge_from` 
    for i in eachindex(from_constraints)
        HerbCore.update_rule_indices!(from_constraints[i], length(merge_to.rules), mapping, from_constraints)
        addconstraint!(merge_to, from_constraints[i])
    end
    # Note: Tests for merging two grammars with constraints can be found in HerbConstraints.
end