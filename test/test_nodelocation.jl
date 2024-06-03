using HerbCore


@testset verbose = true "NodeLoc" begin

    @testset "Replace root with a rulenode" begin
        root = RuleNode(1, [
            RuleNode(2, []),
            RuleNode(3, [
                RuleNode(4, [])
            ])
        ])
        loc = NodeLoc(root, 0)
        new_node = RuleNode(5, [])
        insert!(root, loc, new_node)
        @test get(root, loc) == new_node
    end

    @testset "Replace subtree with hole" begin
        root = RuleNode(1, [
            RuleNode(2, []),
            RuleNode(3, [
                RuleNode(4, [])
            ])
        ])
        loc = NodeLoc(root, 2)
        new_node = Hole([0, 0, 0, 1])
        insert!(root, loc, new_node)
        @test get(root, loc) isa Hole
        @test get(root, loc).domain == [0, 0, 0, 1]
    end
end