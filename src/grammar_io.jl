"""
Writes a context-free grammar in JSON format to the file provided by `filepath`.
"""
function store_cfg(filepath::AbstractString, grammar::ContextFreeGrammar)
    open(filepath, "w") do file
        write(file, JSON.json(grammar, 4)) # indentation = 4
    end
end


"""
Reads a CFG from a JSON file provided in `filepath`.
"""
function read_cfg(filepath::AbstractString)::ContextFreeGrammar
    # Function for converting rules from Dict to Expr. 
    convert_expr(d::Dict{String, Any}) = Expr(Symbol(d["head"]), map(Symbol, d["args"])...)
    convert_expr(x::Any) = x

    # Read JSON file
    json_dict = JSON.parsefile(filepath)
    
    # Convert the JSON dictionary into a CFG
    return ContextFreeGrammar(
        map(convert_expr, json_dict["rules"]), 
        map(Symbol, json_dict["types"]),                                # Convert vector values to Symbol
        json_dict["isterminal"], 
        json_dict["iseval"], 
        Dict([Symbol(k) => v for (k, v) ∈ pairs(json_dict["bytype"])]), # Convert dict keys to Symbol
        map(x -> map(Symbol, x), json_dict["childtypes"])               # Convert values in 2d vector to Symbol
    ) 
end