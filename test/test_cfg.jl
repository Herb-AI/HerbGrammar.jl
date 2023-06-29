@testset verbose=true "CFGs" begin
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
        add_rule!(g₁, :(Real = 3))
        @test g₁.rules == [1, 2, 3]

        # Adding multiple rules in one line
        add_rule!(g₁, :(Real = 4 | 5))
        @test g₁.rules == [1, 2, 3, 4, 5]

        # Adding already existing rules
        add_rule!(g₁, :(Real = 5))
        @test g₁.rules == [1, 2, 3, 4, 5]

        # Adding multiple already existing rules
        add_rule!(g₁, :(Real = |(1:9)))
        @test g₁.rules == collect(1:9)

        # Adding other types
        g₂ = @cfgrammar begin
            Real = 1 | 2 | 3
        end

        add_rule!(g₂, :(Bool = Real ≤ Real))
        @test length(g₂.rules) == 4
        @test :Real ∈ g₂.types
        @test :Bool ∈ g₂.types
        @test g₂.rules[g₂.bytype[:Bool][1]] == :(Real ≤ Real)
        @test g₂.childtypes[g₂.bytype[:Bool][1]] == [:Real, :Real]

    end


    @testset "Writing and loading CFG to/from disk" begin
        g₁ = @cfgrammar begin
            Real = |(1:5)
            Real = 6 | 7 | 8
        end
        
        store_cfg("toy_cfg.grammar", g₁)
        g₂ = read_cfg("toy_cfg.grammar")
        @test :Real ∈ g₂.types
        @test g₂.rules == collect(1:8)

        # delete file afterwards
        rm("toy_cfg.grammar")
    end

    @testset "Writing and loading probabilistic CFG to/from disk" begin
        g₁ = @pcfgrammar begin
            0.5 : Real = |(0:3)
            0.5 : Real = x
        end
        
        store_cfg("toy_pcfg.grammar", g₁)
        g₂ = read_pcfg("toy_pcfg.grammar")
        @test :Real ∈ g₂.types
        @test g₂.rules == [0, 1, 2, 3, :x]
        @test g₂.log_probabilities == g₁.log_probabilities


        # delete file afterwards
        rm("toy_pcfg.grammar")
    end

    @testset "Sampling grammar" begin

        @testset "Sampling tests return proper depth" begin
            arithmetic_grammar = @cfgrammar begin
                X = X * X
                X = X + X
                X = X - X
                X = |(1:4)
            end

            for max_depth in 1:20
                expression_generated = rand(RuleNode, arithmetic_grammar, :X, max_depth)
                depth_generated = depth(expression_generated)
                if depth(expression_generated) > max_depth
                    println(depth_generated," ",max_depth)
                end
                @test depth(expression_generated) <= max_depth
            end
        end
        @testset "Sampling gives the only expression for a certain depth" begin
            grammar = @cfgrammar begin 
                A = B | C | F
                F = G
                C = D
                D = E
            end
            # A->B (depth 1) or A->F->G (depth 2) or A->C->D->E (depth 3)

            # For depth ≤ 1 the only option is A->B
            expression = rand(RuleNode, grammar, :A, 1)
            @test depth(expression) == 1
            @test expression == RuleNode(1)
        end

        @testset "Sampling throws an error if all expressions have a higher depth than max_depth" begin
            grammar = @cfgrammar begin 
                A = B 
                B = C
                C = D
                D = E
                E = F
            end
            # A->B->C->D->E->F (depth 5)
            real_depth = 5
            
            # it does not work for max_depth < 5
            for max_depth in 1:real_depth - 1
                @test_throws ErrorException expression = rand(RuleNode, grammar, :A, max_depth)
            end
            
            # it works for max_depth = 5
            expression = rand(RuleNode, grammar, :A, real_depth)
            @test depth(expression) == real_depth
        end
    end
    
end
