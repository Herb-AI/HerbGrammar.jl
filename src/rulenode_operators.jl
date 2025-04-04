"""
    swap_node(expr::AbstractRuleNode, new_expr::AbstractRuleNode, path::Vector{Int})

Replace a node in `expr`, specified by `path`, with `new_expr`.
Path is a sequence of child indices, starting from the root node.
"""
function swap_node(expr::AbstractRuleNode, new_expr::AbstractRuleNode, path::Vector{Int})
    if length(path) == 1
        expr.children[path[begin]] = new_expr
    else
        swap_node(expr.children[path[begin]], new_expr, path[2:end])
    end
end


"""
    swap_node(expr::RuleNode, node::RuleNode, child_index::Int, new_expr::RuleNode)

Replace child `i` of a node, a part of larger `expr`, with `new_expr`.
"""
function swap_node(expr::RuleNode, node::RuleNode, child_index::Int, new_expr::RuleNode)
    if expr == node 
        node.children[child_index] = new_expr
    else
        for child ∈ expr.children
            swap_node(child, node, child_index, new_expr)
        end
    end
end


"""
    get_rulesequence(node::RuleNode, path::Vector{Int})

Extract the derivation sequence from a path (sequence of child indices) and an [`AbstractRuleNode`](@ref).
If the path is deeper than the deepest node, it returns what it has.
"""
function get_rulesequence(node::RuleNode, path::Vector{Int})
    if get_rule(node) == 0 # sign for empty node 
        return Vector{Int}()
    elseif isempty(node.children) # no children, nowhere to follow the path; still return the index
        return [get_rule(node)]
    elseif isempty(path)
        return [get_rule(node)]
    elseif isassigned(path, 2)
        # at least two items are left in the path
        # need to access the child with get because it can happen that the child is not yet built
        return append!([get_rule(node)], get_rulesequence(get(node.children, path[begin], RuleNode(0)), path[2:end]))
    else
        # if only one item left in the path
        # need to access the child with get because it can happen that the child is not yet built
        return append!([get_rule(node)], get_rulesequence(get(node.children, path[begin], RuleNode(0)), Vector{Int}()))
    end
end

get_rulesequence(::Hole, ::Vector{Int}) = Vector{Int}()

"""
    rulesonleft(node::RuleNode, path::Vector{Int})::Set{Int}

Finds all rules that are used in the left subtree defined by the path.
"""
function rulesonleft(node::RuleNode, path::Vector{Int})::Set{Int}
    if isempty(node.children)
        # if the encountered node is terminal or non-expanded non-terminal, return node id
        Set{Int}(get_rule(node))
    elseif isempty(path)
        # if path is empty, collect the entire subtree
        ruleset = Set{Int}(get_rule(node))
        for ch in node.children
            union!(ruleset, rulesonleft(ch, Vector{Int}()))
        end
        return ruleset 
    elseif length(path) == 1
        # if there is only one element left in the path, collect all children except the one indicated in the path
        ruleset = Set{Int}(get_rule(node))
        for i in 1:path[begin]-1
            union!(ruleset, rulesonleft(node.children[i], Vector{Int}()))
        end
        return ruleset 
    else
        # collect all subtrees up to the child indexed in the path
        ruleset = Set{Int}(get_rule(node))
        for i in 1:path[begin]-1
            union!(ruleset, rulesonleft(node.children[i], Vector{Int}()))
        end
        union!(ruleset, rulesonleft(node.children[path[begin]], path[2:end]))
        return ruleset 
    end
end

rulesonleft(::Hole, ::Vector{Int}) = Set{Int}()


"""
    rulenode2expr(rulenode::AbstractRuleNode, grammar::AbstractGrammar)

Converts an [`AbstractRuleNode`](@ref) into a Julia expression corresponding to the rule definitions in the grammar.
The returned expression can be evaluated with Julia semantics using `eval()`.
"""
function rulenode2expr(rulenode::AbstractRuleNode, grammar::AbstractGrammar)
    if !isfilled(rulenode)
        return _get_hole_type(rulenode, grammar)
    end
    root = deepcopy(grammar.rules[get_rule(rulenode)])
    if !grammar.isterminal[get_rule(rulenode)] # not terminal
        root,_ = _rulenode2expr(root, rulenode, grammar)
    end
    return root
end

function _get_hole_type(hole::AbstractHole, grammar::AbstractGrammar)
    @assert !isfilled(hole) "Hole $(hole) is convertable to an expression. There is no need to represent it using a symbol."
    index = findfirst(hole.domain)
    return isnothing(index) ? :Nothing : grammar.types[index]
end

function _rulenode2expr(expr::Expr, rulenode::AbstractRuleNode, grammar::AbstractGrammar, j=0)
    if isfilled(rulenode)
        for (k,arg) in enumerate(expr.args)
            if isa(arg, Expr)
                expr.args[k],j = _rulenode2expr(arg, rulenode, grammar, j)
            elseif haskey(grammar.bytype, arg)
                child = rulenode.children[j+=1]
                if isfilled(child)
                    expr.args[k] = deepcopy(grammar.rules[get_rule(child)])
                    if !isterminal(grammar, child)
                        expr.args[k],_ = _rulenode2expr(expr.args[k], child, grammar, 0)
                    end
                else
                    expr.args[k] = _get_hole_type(child, grammar)
                end
            end
        end
    end
    return expr, j
end


function _rulenode2expr(typ::Symbol, rulenode::AbstractRuleNode, grammar::AbstractGrammar, j=0)
    @assert isfilled(rulenode) "grammar contains a duplicate rule"
    retval = typ
    if haskey(grammar.bytype, typ)
        child = rulenode.children[1]
        retval = deepcopy(grammar.rules[get_rule(child)])
        if !grammar.isterminal[get_rule(child)]
            retval,_ = _rulenode2expr(retval, child, grammar, 0)
        end
    end
    retval, j
end

# ---------------------------------------------
# expr2rulenode and associated functions
# ---------------------------------------------

function grammar_map_right_to_left(grammar::AbstractGrammar)
    tags = Dict{Any,Any}()
    for (l, r) in zip(grammar.types, grammar.rules)
        tags[r] = l
    end
    return tags
end

function _expr2rulenode(expr::Expr, grammar::AbstractGrammar, tags::Dict{Any,Any})
    if expr.head == :call 

        if !haskey(tags, expr)
       
            parameters = [_expr2rulenode(expr.args[i], grammar, tags) for i in (2:length(expr.args))]
            pl = map( x -> x[1], parameters)
            pr = map( x -> x[2], parameters)
            
            temp = [expr.args[1] ;pl]
            newexpr = Expr(:call, temp...)
            rule = findfirst(==(newexpr), grammar.rules)


            oldpl = copy(pl)
            oldpr = copy(pr)
            pnr = length(pl)

            while isnothing(rule)
                
                updatedrule = findfirst(==(pl[pnr]), grammar.rules)     
                
                if isnothing(updatedrule)
                    pl[pnr] = oldpl[pnr]
                    pr[pnr] = oldpr[pnr]
                    pnr = pnr - 1
                    continue
                end

                pl[pnr] = tags[pl[pnr]]
                pr[pnr] = RuleNode(updatedrule, [pr[pnr]])
  
                temp = [expr.args[1] ;pl]
                newexpr = Expr(:call, temp...)
                rule = findfirst(==(newexpr), grammar.rules)
                
                pnr = length(pl)
            end
            return (tags[newexpr], RuleNode(rule, pr))
        else 
            rule = findfirst(==(expr), grammar.rules)
            return (tags[expr], RuleNode(rule, []))
        end
    elseif expr.head == :block
        (l1, r1) = _expr2rulenode( expr.args[1], grammar, tags)
        (l2, r2) = _expr2rulenode( expr.args[3], grammar, tags)
        
        temp = (l1, l2)

        newexpr = Expr(:block, temp...)
        rule = findfirst(==(newexpr), grammar.rules)

        pl = [l1, l2]
        pr = [r1, r2]

        oldpl = copy(pl)
        oldpr = copy(pr)
        pnr = length(pl)

        while isnothing(rule)
            
            updatedrule = findfirst(==(pl[pnr]), grammar.rules)     
            
            if isnothing(updatedrule)
                pl[pnr] = oldpl[pnr]
                pr[pnr] = oldpr[pnr]
                pnr = pnr - 1
                continue
            end
            
            pl[pnr] = tags[pl[pnr]]
            pr[pnr] = RuleNode(updatedrule, [pr[pnr]])
            
            temp = (pl[1], pl[2])
            newexpr = Expr(:block, temp...)
            rule = findfirst(==(newexpr), grammar.rules)
            
            pnr = length(pl)
        end
        return (tags[newexpr], RuleNode(rule, pr))
        
    elseif expr.head == :quote
        return _expr2rulenode(expr.args[1], grammar, tags)
    else
        error("Only call and block expressions are supported")
    end
end

function _expr2rulenode(expr::Any, grammar::AbstractGrammar, tags::Dict{Any,Any})
    rule = findfirst(==(expr), grammar.rules)
    return (tags[expr], RuleNode(rule, []))
end

"""
    expr2rulenode(expr::Expr, grammar::AbstractGrammar, startSymbol::Symbol)

Converts an expression into a [`AbstractRuleNode`](@ref) corresponding to the rule definitions in the grammar.
"""
function expr2rulenode(expr::Expr, grammar::AbstractGrammar, startSymbol::Symbol)
    tags = grammar_map_right_to_left(grammar)
    (s, rn) = _expr2rulenode(expr, grammar, tags)
    while s != startSymbol
            
        updatedrule = findfirst(==(s), grammar.rules)     
        
        if isnothing(updatedrule)
            error("INVALID STARTING SYMBOL")
        end
            
        s = tags[s]
        rn = RuleNode(updatedrule, [rn])
    end
    return rn
end

"""
    expr2rulenode(expr::Expr, grammar::AbstractGrammar)

Converts an expression into a [`AbstractRuleNode`](@ref) corresponding to the rule definitions in the grammar.
"""
function expr2rulenode(expr::Expr, grammar::AbstractGrammar)
    tags = grammar_map_right_to_left(grammar)
    (s, rn) = _expr2rulenode(expr, grammar, tags)
    return rn
end

"""
    expr2rulenode(expr::Symbol, grammar::AbstractGrammar, startSymbol::Symbol)

Converts an expression into a [`AbstractRuleNode`](@ref) corresponding to the rule definitions in the grammar.
"""
function expr2rulenode(expr::Symbol, grammar::AbstractGrammar, startSymbol::Symbol)
    tags = grammar_map_right_to_left(grammar)
    (s, rn) = expr2rulenode(expr, grammar, tags)
    while s != startSymbol
            
        updatedrule = findfirst(==(s), grammar.rules)     
        
        if isnothing(updatedrule)
            error("INVALID STARTING SYMBOL")
        end
            
        s = tags[s]
        rn = RuleNode(updatedrule, [rn])
    end
    return rn
end

"""
    expr2rulenode(expr::Symbol, grammar::AbstractGrammar)

Converts an expression into a [`AbstractRuleNode`](@ref) corresponding to the rule definitions in the grammar.
"""
function expr2rulenode(expr::Union{Symbol,Number}, grammar::AbstractGrammar)
    tags = grammar_map_right_to_left(grammar)
    (s, rn) = _expr2rulenode(expr, grammar, tags)
    return rn
end

"""
    rulenode_log_probability(node::RuleNode, grammar::AbstractGrammar)

Calculates the log probability associated with a rulenode in a probabilistic grammar.
"""
function rulenode_log_probability(node::RuleNode, grammar::AbstractGrammar)
    return log_probability(grammar, get_rule(node)) + sum((rulenode_log_probability(c, grammar) for c ∈ node.children), init=0)
end

function rulenode_log_probability(hole::AbstractHole, grammar::AbstractGrammar)
    if sum(hole.domain) == 1 # only one element 
        return log_probability(grammar, only(findall(hole.domain)))
    else
        throw(ArgumentError("Log probability of a UniformHole requested, which has more than 1 element within its domain. This is ambiguous."))
    end
end
rulenode_log_probability(::Hole, ::AbstractGrammar) = 0

"""
    max_rulenode_log_probability(rulenode::AbstractRuleNode, grammar::AbstractGrammar)

Calculates the highest possible probability within an `AbstractRuleNode`. 
That is, for each node and its domain, get the highest probability and multiply it with the probabilities of its children, if present. 
As we operate with log probabilities, we sum the logarithms.
"""
function max_rulenode_log_probability(rulenode::RuleNode, grammar::AbstractGrammar)
    return log_probability(grammar, get_rule(rulenode)) + sum((max_rulenode_log_probability(c, grammar) for c ∈ rulenode.children), init=0)
end

function max_rulenode_log_probability(hole::AbstractHole, grammar::AbstractGrammar)
    return maximum(grammar.log_probabilities[findall(hole.domain)]) + sum((max_rulenode_log_probability(c, grammar) for c ∈ hole.children), init=0)
end

function max_rulenode_log_probability(hole::Hole, grammar::AbstractGrammar)
    return maximum(grammar.log_probabilities[findall(hole.domain)])
end


"""
    iscomplete(grammar::AbstractGrammar, node::RuleNode) 

Returns true if the expression represented by the [`RuleNode`](@ref) is a complete expression, 
meaning that it is fully defined and doesn't have any [`Hole`](@ref)s.
"""
function iscomplete(grammar::AbstractGrammar, node::RuleNode) 
    if isterminal(grammar, node)
        return true
    elseif isempty(node.children)
        # if not terminal but has children
        return false
    else
        return all([iscomplete(grammar, c) for c in node.children])
    end
end

iscomplete(grammar::AbstractGrammar, ::Hole) = false


"""
    return_type(grammar::AbstractGrammar, node::RuleNode)

Gives the return type or nonterminal symbol in the production rule used by `node`.
"""
return_type(grammar::AbstractGrammar, node::RuleNode)::Symbol = grammar.types[get_rule(node)]


"""
    return_type(grammar::AbstractGrammar, hole::UniformHole)

Gives the return type or nonterminal symbol in the production rule used by `hole`.
"""
return_type(grammar::AbstractGrammar, hole::UniformHole)::Symbol = grammar.types[findfirst(hole.domain)]


"""
    child_types(grammar::AbstractGrammar, node::RuleNode)

Returns the list of child types (nonterminal symbols) in the production rule used by `node`.
"""
child_types(grammar::AbstractGrammar, node::RuleNode)::Vector{Symbol} = grammar.childtypes[get_rule(node)]


"""
    isterminal(grammar::AbstractGrammar, node::AbstractRuleNode)::Bool

Returns true if the production rule used by `node` is terminal, i.e., does not contain any nonterminal symbols.
"""
isterminal(grammar::AbstractGrammar, node::AbstractRuleNode)::Bool = grammar.isterminal[get_rule(node)]


"""
    nchildren(grammar::AbstractGrammar, node::RuleNode)::Int

Returns the number of children in the production rule used by `node`.
"""
nchildren(grammar::AbstractGrammar, node::RuleNode)::Int = length(child_types(grammar, node))

"""
    isvariable(grammar::AbstractGrammar, node::RuleNode)::Bool

Return true if the rule used by `node` represents a variable in a program (essentially, an input to the program)
"""
isvariable(grammar::AbstractGrammar, node::RuleNode)::Bool = (
    grammar.isterminal[get_rule(node)] &&
    grammar.rules[get_rule(node)] isa Symbol &&
    !_is_defined_in_modules(grammar.rules[get_rule(node)], [Main, Base])
)
"""
    isvariable(grammar::AbstractGrammar, node::RuleNode, mod::Module)::Bool

Return true if the rule used by `node` represents a variable.
    
Taking into account the symbols defined in the given module(s).
"""
isvariable(grammar::AbstractGrammar, node::RuleNode, mod::Module...)::Bool = (
    grammar.isterminal[get_rule(node)] &&
    grammar.rules[get_rule(node)] isa Symbol &&
    !_is_defined_in_modules(grammar.rules[get_rule(node)], [mod..., Main, Base])
)

"""
    isvariable(grammar::AbstractGrammar, ind::Int)::Bool

Return true if the rule with index `ind` represents a variable.
"""
isvariable(grammar::AbstractGrammar, ind::Int)::Bool = (
    grammar.isterminal[ind] &&
    grammar.rules[ind] isa Symbol &&
    !_is_defined_in_modules(grammar.rules[ind], [Main, Base])
)
"""
    isvariable(grammar::AbstractGrammar, ind::Int, mod::Module)::Bool

Return true if the rule with index `ind` represents a variable.
    
Taking into account the symbols defined in the given module(s).
"""
isvariable(grammar::AbstractGrammar, ind::Int, mod::Module...)::Bool = (
    grammar.isterminal[ind] &&
    grammar.rules[ind] isa Symbol &&
    !_is_defined_in_modules(grammar.rules[ind], [mod..., Main, Base])
)

"""
    contains_returntype(node::RuleNode, grammar::AbstractGrammar, sym::Symbol, maxdepth::Int=typemax(Int))

Returns true if the tree rooted at `node` contains at least one node at depth less than `maxdepth`
with the given return type or nonterminal symbol.
"""
function contains_returntype(node::RuleNode, grammar::AbstractGrammar, sym::Symbol, maxdepth::Int=typemax(Int))
    maxdepth < 1 && return false
    if return_type(grammar, node) == sym
        return true
    end
    for c in node.children
        if contains_returntype(c, grammar, sym, maxdepth-1)
            return true
        end
    end
    return false
end
