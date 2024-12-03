module SomeDefinitions
    a_variable_that_is_defined = 7
end

@testset verbose = true "RuleNode Operators" begin
    @testset "Check if a symbol is a variable" begin
        g₁ = @cfgrammar begin
            Real = |(1:5)
            Real = a_variable
            Real = a_variable_that_is_defined
        end

        @test !isvariable(g₁, RuleNode(5, g₁), SomeDefinitions)
        @test isvariable(g₁, RuleNode(6, g₁), SomeDefinitions)
        @test !isvariable(g₁, RuleNode(7, g₁), SomeDefinitions)
        @test isvariable(g₁, RuleNode(7, g₁))
    end

    @testset "Create `RuleNode`s with `Hole`s for children" begin
        g = @csgrammar begin
            A = 1 | 2 | 3
            B = A + A
        end

        r = rulenode_with_empty_children(4, g)

        @test get_children(r)[1].domain == [1, 1, 1, 0]
        @test get_children(r)[2].domain == [1, 1, 1, 0]
    end

    @testset "Create `UniformHole`s with `Hole`s for children" begin
        g = @csgrammar begin
            A = 1 | 2 | 3
            B = (A + A) | (A - A)
        end
        h = uniform_hole_with_empty_children(BitVector([0, 0, 0, 1, 1]), g)

        @test get_children(h)[1].domain == [1, 1, 1, 0, 0]
        @test get_children(h)[2].domain == [1, 1, 1, 0, 0]
    end
end
