@testitem "Constraint valid with respect to a grammar" begin
    import HerbCore: RuleNode
    import HerbConstraints: Forbidden, DomainRuleNode
    import HerbGrammar: @csgrammar, is_constraint_valid

    g = @csgrammar begin
        Int = Int + Int
        Int = 1 | 2
    end
    f = Forbidden(DomainRuleNode(g, [1], [RuleNode(2), RuleNode(3)]))
    @test is_constraint_valid(f, g; allow_empty_children=false)
end
