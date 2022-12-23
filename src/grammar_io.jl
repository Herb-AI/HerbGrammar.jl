using JLD2

"""
Writes a context-free grammar in JSON format to the file provided by `filepath`.
"""
function store_cfg(filepath::AbstractString, grammar::ContextFreeGrammar)
    open(filepath, write=true) do file
        for (type, rule) ∈ zip(grammar.types, grammar.rules)
            println(file, "$type = $rule")
        end
    end
end

"""
Reads a CFG from a file file provided in `filepath`.
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