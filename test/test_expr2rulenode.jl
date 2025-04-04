@testset verbose=true "expr2rulenode" begin

    g1 = @cfgrammar begin
    Number = |(1:2)
    Number = x
    Number = Number + Number 
    Number = Number * Number
    Number = DiffNumber
    DiffNumber = |(3:4)
    end
    
    expr1 = :(1 + 2)
    expr2 = :((x * (1 + 3)) + (4 * x))
    @test expr2rulenode(expr1, g1) == RuleNode(4, [RuleNode(1, []), RuleNode(2, [])])    
    @test expr2rulenode(expr2, g1) == RuleNode(4, [ RuleNode(5, [RuleNode(3, []), RuleNode(4, [RuleNode(1, []), RuleNode(6,[RuleNode(7, [])])])]), RuleNode(5,[RuleNode(6, [RuleNode(8, [])]), RuleNode(3, [])])])


    g2 = @csgrammar begin
        Start = Sequence                   #1
    
        Sequence = Operation                #2
        Sequence = (Operation; Sequence)    #3
        Operation = Transformation          #4
        Operation = ControlStatement        #5
    
        Transformation = moveRight() | moveDown() | moveLeft() | moveUp() | drop() | grab()     #6
        ControlStatement = IF(Condition, Sequence, Sequence)        #12
        ControlStatement = WHILE(Condition, Sequence)               #13
    
        Condition = atTop() | atBottom() | atLeft() | atRight() | notAtTop() | notAtBottom() | notAtLeft() | notAtRight()      #14
    end

    expr3 = :(moveUp())
    expr4 = :(moveUp(); (moveRight()))
    expr5 = :(IF(atTop(), ((moveUp(); (moveRight()))), moveRight()))

    @test expr2rulenode(expr3, g2) == RuleNode(9, [])
    @test expr2rulenode(expr3, g2, :Start) == RuleNode(1, [RuleNode(2, [RuleNode(4, [RuleNode(9, [])])])])

    @test expr2rulenode(expr4, g2) == RuleNode(3, [RuleNode(4, [RuleNode(9, [])]) , RuleNode(2, [RuleNode(4, [RuleNode(6, [])])])])
    @test expr2rulenode(expr4, g2, :Start) == RuleNode(1, [RuleNode(3, [RuleNode(4, [RuleNode(9, [])]) , RuleNode(2, [RuleNode(4, [RuleNode(6, [])])])])])

    @test expr2rulenode(expr5, g2) == RuleNode(12, [RuleNode(14, []), RuleNode(3, [RuleNode(4, [RuleNode(9, [])]) , RuleNode(2, [RuleNode(4, [RuleNode(6, [])])])]), RuleNode(2, [RuleNode(4, [RuleNode(6, [])])])])
    @test expr2rulenode(expr5, g2, :Start) == RuleNode(1, [RuleNode(2, [RuleNode(5, [RuleNode(12, [RuleNode(14, []), RuleNode(3, [RuleNode(4, [RuleNode(9, [])]) , RuleNode(2, [RuleNode(4, [RuleNode(6, [])])])]), RuleNode(2, [RuleNode(4, [RuleNode(6, [])])])])])])])
    
    int_grammar = @csgrammar begin
        Val = 0 | 1 | 2
    end

    int_expr = :(2)
    @test expr2rulenode(int_expr, int_grammar) == RuleNode(3)
    @test rulenode2expr(expr2rulenode(int_expr, int_grammar), int_grammar) == int_expr

    float_grammar = @csgrammar begin
        Val = 0.0 | 1.0 | 2.0 | 3.14
    end

    float_expr = :(3.14)
    @test expr2rulenode(float_expr, float_grammar) == RuleNode(4)
    @test rulenode2expr(expr2rulenode(float_expr, float_grammar), float_grammar) == float_expr
    
    sym_grammar = @csgrammar begin
        Val = x
    end

    sym = :(x)
    @test expr2rulenode(sym, sym_grammar) == RuleNode(1)
    @test rulenode2expr(expr2rulenode(sym, sym_grammar), sym_grammar) == sym
end
