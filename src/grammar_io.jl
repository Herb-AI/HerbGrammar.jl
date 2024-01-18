"""
    store_cfg(filepath::AbstractString, grammar::ContextSensitiveGrammar)

Writes the context free part of a [`ContextSensitiveGrammar`](@ref) to the file provided by `filepath`.
"""
function store_cfg(filepath::AbstractString, grammar::ContextSensitiveGrammar)
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
    read_cfg(filepath::AbstractString)::ContextSensitiveGrammar

Reads the context free part of a [`ContextSensitiveGrammar`](@ref) from the file provided in `filepath`.

!!! danger
    Only open trusted grammars. 
    Parts of the grammar can be passed to Julia's `eval` function.  
"""
function read_cfg(filepath::AbstractString)::ContextSensitiveGrammar
    # Read the contents of the file into a string
    file = open(filepath)
    program::AbstractString = read(file, String)
    close(file)

    # Parse the string into an expression
    ex::Expr = Meta.parse("begin $program end")

    # Convert the expression to a context-free grammar
    return expr2csgrammar(ex)
end

"""
    read_pcfg(filepath::AbstractString)::ContextSensitiveGrammar

Reads the context free part of a probabilistic [`ContextSensitiveGrammar`](@ref) from a file provided in `filepath`.

!!! danger
    Only open trusted grammars. 
    Parts of the grammar can be passed to Julia's `eval` function.  
"""
function read_pcfg(filepath::AbstractString)::ContextSensitiveGrammar
    # Read the contents of the file into a string
    file = open(filepath)
    program::AbstractString = read(file, String)
    close(file)

    # Parse the string into an expression
    ex::Expr = Meta.parse("begin $program end")

    # Convert the expression to a context-free grammar
    return expr2pcsgrammar(ex)
end

"""
    store_csg(grammarpath::AbstractString, constraintspath::AbstractString, g::ContextSensitiveGrammar)

Writes a [`ContextSensitiveGrammar`](@ref) to the files at `grammarpath` and `constraintspath`.
The `grammarpath` file will contain a [`ContextSensitiveGrammar`](@ref) definition, and the
`constraintspath` file will contain the [`Constraint`](@ref)s of the [`ContextSensitiveGrammar`](@ref).
"""
function store_csg(grammarpath::AbstractString, constraintspath::AbstractString, g::ContextSensitiveGrammar)
    # Store grammar as CFG
    store_cfg(grammarpath, g)
    
    # Store constraints separately
    open(constraintspath, write=true) do file
        serialize(file, g.constraints)
    end
end

"""
    read_csg(grammarpath::AbstractString, constraintspath::AbstractString)::ContextSensitiveGrammar

Reads a [`ContextSensitiveGrammar`](@ref) from the files at `grammarpath` and `constraintspath`.

!!! danger
    Only open trusted grammars. 
    Parts of the grammar can be passed to Julia's `eval` function.  
"""
function read_csg(grammarpath::AbstractString, constraintspath::AbstractString)::ContextSensitiveGrammar
    g = read_cfg(grammarpath)
    file = open(constraintspath)
    constraints = deserialize(file)
    close(file)

    return ContextSensitiveGrammar(g.rules, g.types, g.isterminal, 
        g.iseval, g.bytype, g.domains, g.childtypes, g.log_probabilities, constraints)
end

"""
    read_pcsg(grammarpath::AbstractString, constraintspath::AbstractString)::ContextSensitiveGrammar

Reads a probabilistic [`ContextSensitiveGrammar`](@ref) from the files at `grammarpath` and `constraintspath`.

!!! danger
    Only open trusted grammars. 
    Parts of the grammar can be passed to Julia's `eval` function.  
"""
function read_pcsg(grammarpath::AbstractString, constraintspath::AbstractString)::ContextSensitiveGrammar
    g = read_pcfg(grammarpath)
    file = open(constraintspath)
    constraints = deserialize(file)
    close(file)

    return ContextSensitiveGrammar(g.rules, g.types, g.isterminal, 
        g.iseval, g.bytype, g.domains, g.childtypes, g.log_probabilities, constraints)
end


