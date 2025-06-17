using Interfaces: @implements, @interface, requiredtype

# When interfaces are in Core
# import HerbCore.rules
# import HerbCore.types

"""
    CostBasedContextSensitiveGrammar <: AbstractGrammar

Represents a context-sensitive grammar where each rule has an associated cost.
"""
struct CostBasedContextSensitiveGrammar{
    R<:AbstractVector,
    T<:AbstractVector{<:Symbol},
    C<:AbstractVector{<:Real}
} <: AbstractGrammar
    rules::R
    types::T
    costs::C

    function CostBasedContextSensitiveGrammar(rules, types, costs)
        @assert length(rules) == length(types) == length(costs) "The length of rules, their corresponding types, and costs must match"

        return new{typeof(rules),typeof(types),typeof(costs)}(rules, types, costs)
    end

    CostBasedContextSensitiveGrammar() = CostBasedContextSensitiveGrammar([], Symbol[], Real[])
end

const CBCSG = CostBasedContextSensitiveGrammar

@implements CostBasedInterface CBCSG [CBCSG()]
# When interfaces are in Core
# @implements HerbCore.GrammarInterface CBCSG [CBCSG()]

rules(grammar::CBCSG) = grammar.rules
types(grammar::CBCSG) = grammar.types
costs(grammar::CBCSG) = grammar.costs

function Base.show(io::IO, grammar::CBCSG)
    for i in eachindex(rules(grammar))
        println(io, i, ": ", types(grammar)[i], " = ", rules(grammar)[i], ", cost: ", costs(grammar)[i])
    end
end