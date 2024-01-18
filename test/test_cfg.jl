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

        @test_throws ArgumentError add_rule!(g₂, :(Real != Bool))
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

end
