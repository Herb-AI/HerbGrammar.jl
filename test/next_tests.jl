@testitem "Grammar" tags=[:next] begin
    using HerbCore.Next: get_rules, get_rhs
    using HerbGrammar.Next: Grammar, Rule, get_nonterminal_symbols, get_terminal_symbols
    
    nonterminals = [:Int]
    terminals = Symbol.([1, 2, 3])
    g = Grammar(
        nonterminals,
        terminals,
        [
            Rule(:Int, (:Int, :Int)),
            Rule(:Int, (Symbol(1),)),
            Rule(:Int, (Symbol(2),)),
            Rule(:Int, (Symbol(3),)),
        ]
    )
    @test get_nonterminal_symbols(g) == nonterminals
    @test get_terminal_symbols(g) == terminals
    @test length(get_rules(g)) == 4
    @test length(get_rules(x -> any(in(nonterminals), get_rhs(x)), g)) == 1 
    @test length(get_rules(x -> !any(in(nonterminals), get_rhs(x)), g)) == 3
end

@testitem "Attribute Grammar" tags=[:next] begin
    using HerbCore.Next: get_rules, get_rhs
    using HerbGrammar.Next: Attribute, Grammar, Rule, get_attributes, get_nonterminal_symbols, get_terminal_symbols
    
    nonterminals = [:Int]
    terminals = Symbol.([1, 2, 3])
    g = Grammar(
        nonterminals,
        terminals,
        [
            Attribute(Rule(:Int, (:Int, :Int)), (; expr = :(Int + Int))),
            Attribute(Rule(:Int, (Symbol(1),)), (; expr = 1)),
            Attribute(Rule(:Int, (Symbol(2),)), (; expr = 2)),
            Attribute(Rule(:Int, (Symbol(3),)), (; expr = 3)),
        ]
    )
    @test get_nonterminal_symbols(g) == nonterminals
    @test get_terminal_symbols(g) == terminals
    @test length(get_rules(g)) == 4
    @test length(get_rules(x -> any(in(nonterminals), get_rhs(x)), g)) == 1 
    @test length(get_rules(x -> !any(in(nonterminals), get_rhs(x)), g)) == 3
    @test get_attributes.(get_rules(g)) isa Vector{NamedTuple{(:expr,)}}
end
