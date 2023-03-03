"""
Writes a context-free grammar to the file provided by `filepath`.
"""
function store_cfg(filepath::AbstractString, grammar::ContextFreeGrammar)
    open(filepath, write=true) do file
        if !isprobabilistic(grammar)
            for (type, rule) ∈ zip(grammar.types, grammar.rules)
                println(file, "$type = $rule")
            end
        else
            for (type, rule, prob) ∈ zip(grammar.types, grammar.rules, grammar.log_probabilities)
                println(file, "$(ℯ^prob) : $type = $rule")
            end
        end
    end
end

"""
Reads a CFG from a file provided in `filepath`.
Do not open any untrusted grammars.
"""
function read_cfg(filepath::AbstractString)::ContextFreeGrammar
    # Read the contents of the file into a string
    file = open(filepath)
    program::AbstractString = read(file, String)
    close(file)

    # Parse the string into an expression
    ex::Expr = Meta.parse("begin $program end")

    # Convert the expression to a context-free grammar
    return expr2cfgrammar(ex)
end

"""
Reads a probabilistic CFG from a file provided in `filepath`.
Do not open any untrusted grammars.
"""
function read_pcfg(filepath::AbstractString)::ContextFreeGrammar
    # Read the contents of the file into a string
    file = open(filepath)
    program::AbstractString = read(file, String)
    close(file)

    # Parse the string into an expression
    ex::Expr = Meta.parse("begin $program end")

    # Convert the expression to a context-free grammar
    return expr2pcfgrammar(ex)
end

"""
Writes a context-sensitive grammar to the files at `grammarpath` and `constraintspath`.
The `grammarpath` file will contain a CFG definition, and the
`constraintspath` file will contain the constraints of the CSG.
"""
function store_csg(grammarpath::AbstractString, constraintspath::AbstractString, grammar::ContextSensitiveGrammar)
    # Store grammar as CFG
    store_cfg(grammarpath, ContextFreeGrammar(grammar.rules, grammar.types, 
        grammar.isterminal, grammar.iseval, grammar.bytype, grammar.childtypes, grammar.log_probabilities))
    
    # Store constraints separately
    open(constraintspath, write=true) do file
        serialize(file, grammar.constraints)
    end
end

"""
Reads a CSG from the files at `grammarpath` and `constraintspath`.
The grammar path may also point to a CFG.
Do not open any untrusted grammars.
"""
function read_csg(grammarpath::AbstractString, constraintspath::AbstractString)::ContextSensitiveGrammar
    g = read_cfg(grammarpath)
    file = open(constraintspath)
    constraints = deserialize(file)
    close(file)

    return ContextSensitiveGrammar(g.rules, g.types, g.isterminal, 
        g.iseval, g.bytype, g.childtypes, g.log_probabilities, constraints)
end

"""
Reads a probabilistic CSG from the files at `grammarpath` and `constraintspath`.
The grammar path may also point to a CFG.
Do not open any untrusted grammars.
"""
function read_pcsg(grammarpath::AbstractString, constraintspath::AbstractString)::ContextSensitiveGrammar
    g = read_pcfg(grammarpath)
    file = open(constraintspath)
    constraints = deserialize(file)
    close(file)

    return ContextSensitiveGrammar(g.rules, g.types, g.isterminal, 
        g.iseval, g.bytype, g.childtypes, g.log_probabilities, constraints)
end


