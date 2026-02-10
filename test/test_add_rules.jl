@testset "add_new_rules_test" begin
    grammar = @csgrammar begin
        Start = Expr                # 1                
        Expr = Operation            # 2             
        Operation = Expr + Expr     # 3                    
        Operation = Expr * Expr     # 4                 
        Operation = Expr - Expr     # 5                 
        Expr = Val                  # 6     
        Val = 1                     # 7 
        Val = 0                     # 8 
    end

    @testset "add_full_rule" begin 
        g = deepcopy(grammar)
        rule = RuleNode(3, [RuleNode(6, [RuleNode(7)]), RuleNode(6, [RuleNode(7)])])
        add_rule!(g, rule)

        @test g.rules[9] == :(1 + 1)
        @test return_type(g, 9) == :Operation
    end

    @testset "add_filled_hole_rule" begin
        g = deepcopy(grammar)
        rule = RuleNode(3, [RuleNode(6, [RuleNode(7)]), UniformHole([0, 1, 0, 0, 0, 1, 0, 0])])
        add_rule!(g, rule)

        @test g.rules[9] == :(1 + Expr)
        @test return_type(g, 9) == :Operation
    end

    @testset "add_filled_hole_rule" begin
        g = deepcopy(grammar)
        rule = RuleNode(2, [UniformHole([0, 0, 1, 1, 1, 1, 0, 0], [RuleNode(6, [RuleNode(7)]), RuleNode(6, [RuleNode(7)])])])
        expr = rulenode2expr(rule, g)
        @show expr
        add_rule!(g, rule)
        @test return_type(g, 9) == :Operation
    end
end