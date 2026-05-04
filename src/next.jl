module Next
using HerbCore: AbstractGrammar, AbstractRuleNode
import HerbCore.Next as HerbCore
using .HerbCore: AbstractRule, get_nonterminal_symbols, get_terminal_symbols, get_lhs, get_rhs, get_rules

struct Grammar{R<:AbstractRule} <: AbstractGrammar
    nonterminals::Vector{Symbol}
    terminals::Vector{Symbol}
    rules::Vector{R}

    function Grammar(nonterminals, terminals, rules::Vector{R}) where R
        if !isempty(intersect(terminals, nonterminals))
            error(lazy"Terminals and nonterminals must be disjoint subsets ($(intersect(terminals, nonterminals)) are in both).")
        end
        lhs = get_lhs.(rules)
        if !issubset(lhs, nonterminals)
            error(lazy"All of the left-hand sides of the rules must be non-terminal symbols ($(filter(x -> !(x in nonterminals), lhs)) are not non-terminals).")
        end
        rhs = collect(Iterators.flatten(get_rhs.(rules)))
        if !issubset(rhs, union(terminals, nonterminals))
            @info "error..." string(nonterminals) string(terminals) string(rhs)
            error(lazy"All of the right-hand sides of the rules must have (non-)terminal symbols ($(filter(x -> !(x in nonterminals) && !(x in terminals), rhs)) are neither).")
        end
        
        return new{R}(nonterminals, terminals, rules)
    end
end
HerbCore.get_nonterminal_symbols(g::Grammar) = g.nonterminals
HerbCore.get_terminal_symbols(g::Grammar) = g.terminals
HerbCore.get_rules(g::Grammar) = g.rules

get_rule(r::AbstractRule) = r.rule

struct Rule{N} <: AbstractRule
    lhs::Symbol
    rhs::NTuple{N,Symbol}
end
get_rule(r::Rule) = r
HerbCore.get_lhs(r::Rule) = r.lhs
HerbCore.get_rhs(r::Rule) = r.rhs
nonterminals(r::Rule) = r.rhs
isterminal(r::Rule) = isempty(nonterminals(r))

function Base.isless(a::Rule, b::Rule)
    lhsa, lhsb = get_lhs(a), get_lhs(b)
    if isless(lhsa, lhsb)
        return true
    elseif isequal(lhsa, lhsb)
        return isless(get_rhs(a), get_rhs(b))
    else
        return false
    end
end

struct Context{P<:AbstractRuleNode,R<:AbstractRule} <: AbstractRule
    α::P
    rule::R
    β::P
end

"""
    get_context(rule::AbstractRule)

Get the context of the rule.
"""
get_context(cr::Context) = (; α = cr.α, β = cr.β)

HerbCore.get_lhs(cr::Context) = contextualize(cr.α, get_lhs(get_rule(cr)), cr.β) 
HerbCore.get_rhs(cr::Context) = contextualize(cr.α, get_rhs(get_rule(cr)), cr.β)

struct Attribute{A,R} <: AbstractRule
    rule::R
    attributes::A
end

"""
    get_attributes(rule::AbstractRule)

Get the attribute(s) of the `rule`.
"""
get_attributes(ar::Attribute) = ar.attributes
get_attributes(cr::Context{<:AbstractRuleNode, <:Attribute}) = get_attributes(cr.rule)

HerbCore.get_lhs(ar::Attribute) = get_lhs(ar.rule)
HerbCore.get_rhs(ar::Attribute) = get_rhs(ar.rule)
get_context(ar::Attribute{<:Any,<:Context}) = get_context(ar.rule)
end
