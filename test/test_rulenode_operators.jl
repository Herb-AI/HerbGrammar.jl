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
    @testset "Check typecheck for insert!" begin
        g = @cfgrammar begin
            Start = Int + Int
            Int = 1
            Int = 2
            B = "notgood"
        end

        root = RuleNode(1, [RuleNode(2), RuleNode(2)])  # 1 + 1
        replacement = RuleNode(4)   # notgood 
        @test rulenode2expr(replacement, g) == :("notgood")
        location = NodeLoc(root, 1) # first child

        # attempting to replace type Int by type B should not work
        @test_throws HerbGrammar.RuleNodeTypeCheckError insert!(root, location, replacement, g)

        root = RuleNode(1, [RuleNode(2), RuleNode(2)])  # 1 + 1
        replacement = RuleNode(3)   # number 2 
        @test rulenode2expr(replacement, g) == :2
        location = NodeLoc(root, 1) # first child

        # replacing from (1 + 1) -> (2 + 1) should work
        insert!(root, location, replacement, g)

        @test rulenode2expr(root, g) == :(2 + 1)
    end
end
