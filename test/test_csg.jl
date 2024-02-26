@testset verbose=true "CSGs" begin
    @testset "Create empty grammar" begin
        g = @csgrammar begin end
        @test isempty(g.rules)
        @test isempty(g.types)
        @test isempty(g.isterminal)
        @test isempty(g.iseval)
        @test isempty(g.bytype)
        @test isempty(g.domains)
        @test isempty(g.childtypes)
        @test isnothing(g.log_probabilities)
    end

    @testset "Creating grammars" begin
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


    @testset "Adding rules to grammar" begin
        g₁ = @csgrammar begin
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
        g₂ = @csgrammar begin
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

    @testset "Merging two grammars" begin
        g₁ = @csgrammar begin
            Number = |(1:2)
            Number = x
        end

        g₂ = @csgrammar begin
            Real = Real + Real
            Real = Real * Real
        end

        merge_grammars!(g₁, g₂)

        @test length(g₁.rules) == 5
        @test :Real ∈ g₁.types
    end

    @testset "Writing and loading CSG to/from disk" begin
        g₁ = @csgrammar begin
            Real = |(1:5)
            Real = 6 | 7 | 8
        end
        
        store_csg(g₁, "toy_cfg.grammar")
        g₂ = read_csg("toy_cfg.grammar")
        @test :Real ∈ g₂.types
        @test g₂.rules == collect(1:8)

        # delete file afterwards
        rm("toy_cfg.grammar")
    end

    @testset "Writing and loading probabilistic CSG to/from disk" begin
        g₁ = @pcsgrammar begin
            0.5 : Real = |(0:3)
            0.5 : Real = x
        end
        
        store_csg(g₁, "toy_pcfg.grammar")
        g₂ = read_pcsg("toy_pcfg.grammar")
        @test :Real ∈ g₂.types
        @test g₂.rules == [0, 1, 2, 3, :x]
        @test g₂.log_probabilities == g₁.log_probabilities


        # delete file afterwards
        rm("toy_pcfg.grammar")
    end

    @testset "creating probabilistic CSG" begin
        g = @pcsgrammar begin
            0.5 : R = |(0:2)
            0.3 : R = x
            0.2 : B = true | false
        end
        
        @test sum(map(exp, g.log_probabilities[g.bytype[:R]])) ≈ 1.0
        @test sum(map(exp, g.log_probabilities[g.bytype[:B]])) ≈ 1.0
        @test g.bytype[:R] == Int[1,2,3,4]
        @test g.bytype[:B] == Int[5,6]
        @test :R ∈ g.types && :B ∈ g.types
    end

    @testset "creating a non-normalized PCSG" begin
        g = @pcsgrammar begin
            0.5 : R = |(0:2)
            0.5 : R = x
            0.5 : B = true | false
        end
        
        @test sum(map(exp, g.log_probabilities[g.bytype[:R]])) ≈ 1.0
        @test sum(map(exp, g.log_probabilities[g.bytype[:B]])) ≈ 1.0
        @test g.rules == [0, 1, 2, :x, :true, :false]
        @test g.bytype[:R] == Int[1,2,3,4]
        @test g.bytype[:B] == Int[5,6]
        @test :R ∈ g.types && :B ∈ g.types
    end

    @testset "Adding a rule to a probabilistic CSG" begin
        g = @pcsgrammar begin
            0.5 : R = x
            0.5 : R = R + R
        end

        add_rule!(g, 0.5, :(R = 1 | 2))

        @test g.rules == [:x, :(R + R), 1, 2]
        
        add_rule!(g, 0.5, :(B = t | f))
        
        @test g.bytype[:B] == Int[5, 6]
        @test sum(map(exp, g.log_probabilities[g.bytype[:R]])) ≈ 1.0
        @test sum(map(exp, g.log_probabilities[g.bytype[:B]])) ≈ 1.0
    end
    
    @testset "Test that strict equality is used during rule creation" begin
        g₁ = @csgrammar begin
            R = x
            R = R + R
        end

        add_rule!(g₁, :(R = 1 | 2))

        add_rule!(g₁,:(Bool = true))

        @test all(g₁.rules .== [:x, :(R + R), 1, 2, true])

        g₁ = @csgrammar begin
            R = x
            R = R + R
        end

        add_rule!(g₁,:(Bool = true))

        add_rule!(g₁, :(R = 1 | 2))

        @test all(g₁.rules .== [:x, :(R + R), true, 1, 2])
    end

end
