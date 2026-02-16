@testset "Adding constraints" verbose=true begin
    
    @testset "too many children" begin
        grammar = @csgrammar begin
            Int = Int + 1
            Int = 0
        end
        t = RuleNode(1, [RuleNode(2), RuleNode(2)])
        addconstraint!(grammar, Forbidden(t))
        @show grammar.constraints
        @test length(grammar.constraints) == 0
    end

    # @testset "Incorrect tree" begin
    #     grammar = @csgrammar begin
    #         Int = Zero
    #         Int = Int +  1
    #         Zero = 0
    #     end
    #     tw = RuleNode(1, [RuleNode(3)])
    #     @test_throws ErrorException addconstraint!(deepcopy(grammar), Forbidden(tw))
    #     t = RuleNode(1, RuleNode(2, [RuleNode(3)]))
    #     @test_nowarn addconstraint!(deepcopy(grammar), Forbidden(t))
    #     @show grammar.constraints
    # end

    # @testset "Incorrect with holes" begin
    #     grammar = @csgrammar begin
    #         Exp = Op
    #         Op = Exp + Exp
    #         Op = Exp * Exp
    #         Exp = 0
    #         Exp = 1
    #     end

    #     tw = DomainRuleNode(BitVector([1, 1, 1, 0, 0]), [RuleNode(4), RuleNode(4)])
    #     @test_throws ErrorException addconstraint!(deepcopy(grammar), Forbidden(tw))
    #     t = DomainRuleNode(BitVector([0, 1, 1, 0, 0]), [RuleNode(4), RuleNode(4)])
    #     @test_nowarn addconstraint!(deepcopy(grammar), Forbidden(t))
    # end

end