module DefiningAVariable
    x = 1
end
@testset "SymbolTable Tests" begin
    g = @cfgrammar begin
        Real = |(1:9)
        Real = x
    end

    st = grammar2symboltable(g, DefiningAVariable)
    @test st[:x] == 1

    @test_warn r"deprecated" st = SymbolTable(g, DefiningAVariable)
    @test st[:x] == 1
end
