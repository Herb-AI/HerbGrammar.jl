module Grammars

import TreeView: walk_tree
using AbstractTrees
using DataStructures # NodeRecycler
using Serialization # grammar_io

include("rulenode.jl")
include("grammar_base.jl")
include("rulenode_operators.jl")
include("utils.jl")
include("cfg.jl")

include("csg/csg.jl")
include("csg/context.jl")

include("grammar_io.jl")



export 
    Grammar,
    ContextFreeGrammar,

    Constraint,
    ContextSensitiveGrammar,
    RuleNode,

    @cfgrammar,
    expr2cfgrammar,
    max_arity,
    depth,
    node_depth,
    isterminal,
    iseval,
    isvariable,
    return_type,
    contains_returntype,
    nchildren,
    child_types,
    get_childtypes,
    nonterminals,
    iscomplete,

    @csgrammar,
    expr2csgrammar,
    addconstraint!,

    GrammarContext,
    addparent!,
    copy_and_insert,

    ComesAfter,
    Ordered,
    Forbidden,
    propagate,
    propagate_index,

    SymbolTable,
    
    change_expr,
    swap_node,
    get_rulesequence,
    rulesoftype,
    rulesonleft,

    NodeRecycler,
    recycle!

    mindepth_map,
    mindepth,
    containedin,
    subsequenceof,
    has_children,

    store_cfg,
    read_cfg,
    store_csg,
    read_csg,
    add_rule!,
    remove_rule!,
    cleanup_removed_rules!

end # module