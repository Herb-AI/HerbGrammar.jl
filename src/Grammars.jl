module Grammars

import TreeView: walk_tree
using AbstractTrees
using DataStructures # NodeRecycler
using Serialization # grammar_io

include("rulenode.jl")
include("grammar_base.jl")
include("rulenode_operators.jl")
include("utils.jl")
include("nodelocation.jl")
include("sampling.jl")
include("grammar_io.jl")


include("cfg/cfg.jl")
include("cfg/probabilistic_cfg.jl")

include("csg/csg.jl")
include("csg/context.jl")
include("csg/probabilistic_csg.jl")

include("grammar_io.jl")

export 
    Grammar,
    ContextFree, 
    ContextSensitive,

    ContextFreeGrammar,

    Constraint,
    ContextSensitiveGrammar,
    RuleNode,
    NodeLoc,

    ProbabilisticCFG,

    @cfgrammar,
    expr2cfgrammar,
    max_arity,
    depth,
    node_depth,
    isterminal,
    sample,
    iseval,
    log_probability,
    probability,
    isprobabilistic,
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
    cfg2csg,
    addconstraint!,

    GrammarContext,
    addparent!,
    copy_and_insert,

    @pcfgrammar,
    expr2pcfgrammar,

    @pcsgrammar,
    expr2pcsgrammar,

    SymbolTable,
    
    change_expr,
    swap_node,
    get_rulesequence,
    rulesoftype,
    rulesonleft,
    rulenode2expr,
    rulenode_log_probability,

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