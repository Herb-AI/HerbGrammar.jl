@testset "SymbolTable Tests" begin
    x = 1
    g₁ = @cfgrammar begin
        Real = |(1:9)
        Real = x
    end

    st = grammar2symboltable(g₁)
    @test !isnothing(st[:x])
end