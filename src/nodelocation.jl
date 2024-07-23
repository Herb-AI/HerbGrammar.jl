"""
NodeLoc
A helper struct that points to a node in the tree via its parent such that the child can be easily
swapped out.
If i is 0 the node pointed to is the root node and parent is the node itself.
"""
struct NodeLoc
    parent::RuleNode
    i::Int
end

"""
root_node_loc(root::RuleNode)
Returns a NodeLoc pointing to the root node.
"""
root_node_loc(root::RuleNode) = NodeLoc(root, 0)

"""
get(root::AbstractRuleNode, loc::NodeLoc)
Obtain the node pointed to by loc.
"""
function Base.get(root::AbstractRuleNode, loc::NodeLoc)
    parent, i = loc.parent, loc.i
    if loc.i > 0
        return parent.children[i]
    else
        return root
    end
end

struct RuleNodeTypeCheckError <: Exception
    message::String
end

Base.showerror(io::IO, e::RuleNodeTypeCheckError) = print(io, e.message)

"""
insert!(loc::NodeLoc, rulenode::RuleNode)
Replaces the subtree pointed to by loc with the given rulenode.
"""
function Base.insert!(root::RuleNode, loc::NodeLoc, rulenode::RuleNode, grammar::AbstractGrammar)
	subtree = get(root, loc)
	return_type_subtree 	  = return_type(grammar, subtree.ind)
	return_type_replacement = return_type(grammar, rulenode.ind)
	# if the types do not match throw an error
	if return_type_replacement !== return_type_subtree 
		throw(RuleNodeTypeCheckError("The provided replacement node does have the correct type to be replaced in the tree. 
					The subtree of the current tree expects a rule with type $return_type_subtree , but 
					the provided replacement has type $return_type_replacement"))
	end

	parent, i = loc.parent, loc.i
	if loc.i > 0
		parent.children[i] = rulenode
	else
		root.ind = rulenode.ind
		root._val = rulenode._val
		root.children = rulenode.children
	end
	return root
end
