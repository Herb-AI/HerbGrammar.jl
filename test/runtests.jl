using Aqua
using HerbCore
using HerbGrammar
using Test


@testset "HerbGrammar.jl" verbose=true begin
    @testset "Aqua.jl Checks" Aqua.test_all(HerbGrammar)
    include("test_csg.jl")
    include("test_rulenode_operators.jl")
    include("test_rulenode2expr.jl")
    include("test_expr2rulenode.jl")
end
