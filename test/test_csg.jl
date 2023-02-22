@testset verbose=true "CSGs" begin

    g₁ = @csgrammar begin
        Real = |(1:5)
        Real = 6 | 7 | 8
        Real = Real + Real
        Real = Real * Real
    end

    @testset "Propagating comesafter" begin
        constraint = ComesAfter(1, [9])
        context = GrammarContext(RuleNode(10), [1])
        domain = propagate(constraint, context, Vector(1:9))
        @test domain == Vector(2:9)
    end

    @testset "Propagating ordered" begin
        constraint = Ordered([2, 1])
        context = GrammarContext(RuleNode(10, [RuleNode(3)]), [2])
        domain = propagate(constraint, context, Vector(1:9))
        @test domain == Vector(2:9)
    end

    @testset "Propagating forbidden" begin
        constraint = Forbidden([10, 1])
        context = GrammarContext(RuleNode(10, [RuleNode(3)]), [2])
        domain = propagate(constraint, context, Vector(1:9))
        @test domain == Vector(2:9)
    end

    @testset "Writing and loading CSG to/from disk" begin
        addconstraint!(g₁, ComesAfter(1, [9]))
        addconstraint!(g₁, Forbidden([9, 2]))
        addconstraint!(g₁, Ordered([1, 2]))

        Grammars.store_csg("toy_csg_grammar.grammar", "toy_csg_grammar.constraints", g₁)
        g₂ = Grammars.read_csg("toy_csg_grammar.grammar", "toy_csg_grammar.constraints")
        @test :Real ∈ g₂.types
        @test all(x ∈ g₂.rules for x ∈ 1:8)
        @test :(Real + Real) ∈ g₂.rules
        @test any(c isa ComesAfter && c.rule == 1 && c.predecessors == [9] for c ∈ g₂.constraints)
        @test any(c isa Forbidden && c.sequence == [9, 2] for c ∈ g₂.constraints)
        @test any(c isa Ordered && c.order == [1, 2] for c ∈ g₂.constraints)
        @test length(g₂.constraints) == length(g₁.constraints)

        rm("toy_csg_grammar.grammar")
        rm("toy_csg_grammar.constraints")
    end
end