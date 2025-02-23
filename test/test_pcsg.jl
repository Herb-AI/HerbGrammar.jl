@testset verbose=true "Probabilistic CSGs" begin
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

    @testset "Creating probabilistic CSG" begin
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

    @testset "Creating a non-normalized PCSG" begin
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

    @testset "Creating a non-probabilistic rule in a PCSG" begin
        expected_log = (
            :error,
            "Rule without probability encountered in probabilistic grammar. Rule ignored."
        )

        @test_logs expected_log match_mode=:any begin
            @pcsgrammar begin
                0.5 : R = x
                R = R + R
            end
        end
    end

    @testset "Make csg probabilistic" begin
        grammar = @csgrammar begin
            R = |(1:3)       
            S = |(1:2)
        end
        # Test correct initialization
        @test !isprobabilistic(grammar)
        init_probabilities!(grammar)
        @test isprobabilistic(grammar)

        probs = grammar.log_probabilities
        
        # Test equivalence of probabilities
        @test probs[1] == probs[2] == probs[3]
        @test probs[end-1] == probs[end]

        # Test values
        @test all(x -> isapprox(x, 1/3), exp.(probs)[1:3])
        @test all(x -> isapprox(x, 1/2), exp.(probs)[4:5])
    
        @test_logs (:warn, "Tried to init probabilities for grammar, but it is already probabilistic. No changes are made.") init_probabilities!(grammar)
    end

    @testset "Test normalize! csg" begin
        grammar = @csgrammar begin
            R = |(1:3)       
            S = |(1:2)
        end

        @test_logs (:warn, "Requesting normalization in a non-probabilistic grammar. Uniform distribution is assumed.") normalize!(grammar)

        grammar.log_probabilities = zeros(length(grammar.rules))
        
        normalize!(grammar)

        probs = grammar.log_probabilities
        
        # Test values
        @test all(x -> isapprox(x, 1/3), exp.(probs)[1:3])
        @test all(x -> isapprox(x, 1/2), exp.(probs)[4:5])
    end
end