using Test
using Grammars

@testset "creating grammars" begin
    g₁ = @cfgrammar begin
        Real = |(1:9)
    end
    @test g₁.rules == collect(1:9)
    @test :Real ∈ g₁.types

    g₂ = @cfgrammar begin
        Real = |([1,2,3])
    end
    @test g₂.rules == [1,2,3]

    g₃ = @cfgrammar begin
        Real = 1 | 2 | 3
    end
    @test g₃.rules == [1,2,3]
end

@testset "adding rules to grammar" begin
    g₁ = @cfgrammar begin
        Real = |(1:2)
    end

    # Basic adding
    Grammars.add_rule!(g₁, :(Real = 3))
    @test g₁.rules == [1, 2, 3]

    # Adding multiple rules in one line
    Grammars.add_rule!(g₁, :(Real = 4 | 5))
    @test g₁.rules == [1, 2, 3, 4, 5]

    # Adding already existing rules
    Grammars.add_rule!(g₁, :(Real = 5))
    @test g₁.rules == [1, 2, 3, 4, 5]

    # Adding multiple already existing rules
    Grammars.add_rule!(g₁, :(Real = |(1:9)))
    @test g₁.rules == collect(1:9)

    # Adding other types
    g₂ = @cfgrammar begin
        Real = 1 | 2 | 3
    end

    Grammars.add_rule!(g₂, :(Bool = Real ≤ Real))
    @test length(g₂.rules) == 4
    @test :Real ∈ g₂.types
    @test :Bool ∈ g₂.types
    @test g₂.rules[g₂.bytype[:Bool][1]] == :(Real ≤ Real)
    @test g₂.childtypes[g₂.bytype[:Bool][1]] == [:Real, :Real]


end