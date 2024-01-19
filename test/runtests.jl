using HerbGrammar
using Test

@testset "HerbGrammar.jl" verbose=true begin
    include("test_cfg.jl")
    include("test_rulenode_operators.jl")
end
