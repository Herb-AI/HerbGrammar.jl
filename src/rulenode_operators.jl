HerbCore.RuleNode(ind::Int, grammar::Grammar) = RuleNode(ind, nothing, [Hole(get_domain(grammar, type)) for type ∈ grammar.childtypes[ind]])
HerbCore.RuleNode(ind::Int, _val::Any, grammar::Grammar) = RuleNode(ind, _val, [Hole(get_domain(grammar, type)) for type ∈ grammar.childtypes[ind]])

rulesoftype(::Hole, ::Set{Int}) = Set()
rulesoftype(node::RuleNode, grammar::Grammar, ruletype::Symbol) = rulesoftype(node, Set(grammar[ruletype]))
rulesoftype(::Hole, ::Grammar, ::Symbol) = Set()


"""
Returns all rules of a specific type used in a RuleNode but not in the ignoreNode.
"""
function rulesoftype(node::RuleNode, ruleset::Set{Int}, ignoreNode::RuleNode)
	retval = Set()

	if node == ignoreNode
		return retval
	end

	if node.ind in ruleset
		union!(retval, [node.ind])
	end

	if isempty(node.children)
		return retval
	else
		for child in node.children
			union!(retval, rulesoftype(child, ruleset))
		end

		return retval
	end
end
rulesoftype(::Hole, ::Set{Int}, ::RuleNode) = Set()

rulesoftype(node::RuleNode, grammar::Grammar, ruletype::Symbol, ignoreNode::RuleNode) = rulesoftype(node, Set(grammar[ruletype]), ignoreNode)
rulesoftype(::Hole, ::Grammar, ::Symbol, ::RuleNode) = Set()

"""
Converts a rulenode into a julia expression. 
The returned expression can be evaluated with Julia semantics using eval().
"""
function rulenode2expr(rulenode::RuleNode, grammar::Grammar)
	root = (rulenode._val !== nothing) ?
		rulenode._val : deepcopy(grammar.rules[rulenode.ind])
	if !grammar.isterminal[rulenode.ind] # not terminal
		root,_ = _rulenode2expr(root, rulenode, grammar)
	end
	return root
end


function _rulenode2expr(expr::Expr, rulenode::RuleNode, grammar::Grammar, j=0)
	for (k,arg) in enumerate(expr.args)
		if isa(arg, Expr)
			expr.args[k],j = _rulenode2expr(arg, rulenode, grammar, j)
		elseif haskey(grammar.bytype, arg)
			child = rulenode.children[j+=1]
			expr.args[k] = (child._val !== nothing) ?
				child._val : deepcopy(grammar.rules[child.ind])
			if !isterminal(grammar, child)
				expr.args[k],_ = _rulenode2expr(expr.args[k], child, grammar, 0)
			end
		end
	end
	return expr, j
end


function _rulenode2expr(typ::Symbol, rulenode::RuleNode, grammar::Grammar, j=0)
	retval = typ
		if haskey(grammar.bytype, typ)
			child = rulenode.children[1]
			retval = (child._val !== nothing) ?
				child._val : deepcopy(grammar.rules[child.ind])
			if !grammar.isterminal[child.ind]
				retval,_ = _rulenode2expr(retval, child, grammar, 0)
			end
		end
	retval, j
end


"""
Calculates the log probability associated with a rulenode in a probabilistic grammar.
"""
function rulenode_log_probability(node::RuleNode, grammar::Grammar)
	log_probability(grammar, node.ind) + sum((rulenode_log_probability(c, grammar) for c ∈ node.children), init=1)
end

rulenode_log_probability(::Hole, ::Grammar) = 1


"""
Returns true if the expression given by the node is complete expression, i.e., all leaves are terminal symbols
"""
function iscomplete(grammar::Grammar, node::RuleNode) 
	if isterminal(grammar, node)
		return true
	elseif isempty(node.children)
		# if not terminal but has children
		return false
	else
		return all([iscomplete(grammar, c) for c in node.children])
	end
end

iscomplete(grammar::Grammar, ::Hole) = false


"""
Returns the return type in the production rule used by node.
"""
return_type(grammar::Grammar, node::RuleNode) = grammar.types[node.ind]


"""
Returns the list of child types in the production rule used by node.
"""
child_types(grammar::Grammar, node::RuleNode) = grammar.childtypes[node.ind]


"""
Returns true if the production rule used by node is terminal, i.e., does not contain any nonterminal symbols.
"""
isterminal(grammar::Grammar, node::RuleNode) = grammar.isterminal[node.ind]


"""
Returns the number of children in the production rule used by node.
"""
nchildren(grammar::Grammar, node::RuleNode) = length(child_types(grammar, node))


"""
Returns true if the rule used by the node represents a variable.
      
TODO: Check if variable is given an assignment in main module or any module 
where definitions for blocks in the grammar might be given. (See SymbolTable)
"""
isvariable(grammar::Grammar, node::RuleNode) = grammar.isterminal[node.ind] && grammar.rules[node.ind] isa Symbol

isvariable(grammar::Grammar, ind::Int) = grammar.isterminal[ind] && grammar.rules[ind] isa Symbol


"""
Returns true if the tree rooted at node contains at least one node at depth less than maxdepth
with the given return type.
"""
function contains_returntype(node::RuleNode, grammar::Grammar, sym::Symbol, maxdepth::Int=typemax(Int))
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



function Base.display(rulenode::RuleNode, grammar::Grammar)
	root = rulenode2expr(rulenode, grammar)
	if isa(root, Expr)
	    walk_tree(root)
	else
	    root
	end
end
