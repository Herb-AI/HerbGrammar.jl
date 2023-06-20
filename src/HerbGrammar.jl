module HerbGrammar

import TreeView: walk_tree
using AbstractTrees
using DataStructures # NodeRecycler
using Serialization # grammar_io

include("grammar_base.jl")
include("rulenode.jl")
include("rulenode_operators.jl")
include("utils.jl")
include("cfg/cfg.jl")
include("cfg/probabilistic_cfg.jl")

include("csg/csg.jl")
include("csg/probabilistic_csg.jl")

include("grammar_io.jl")

export 
    Grammar,
    ContextFree, 
    ContextSensitive,

    ContextFreeGrammar,

    Constraint,
    ContextSensitiveGrammar,
    AbstractRuleNode,
    RuleNode,
    Hole,
    HoleReference,

    ProbabilisticCFG,

    @cfgrammar,
    expr2cfgrammar,
    max_arity,
    depth,
    node_depth,
    isterminal,
    iseval,
    log_probability,
    probability,
    isprobabilistic,
    isvariable,
    return_type,
    contains_returntype,
    contains_hole,
    nchildren,
    child_types,
    get_domain,
    get_childtypes,
    nonterminals,
    iscomplete,
    parse_rule!,

    @csgrammar,
    expr2csgrammar,
    cfg2csg,
    clearconstraints!,
    addconstraint!,

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
    get_node_at_location,
    rulenode2expr,
    rulenode_log_probability,

    NodeRecycler,
    recycle!,

    mindepth_map,
    mindepth,
    containedin,
    subsequenceof,
    has_children,

    store_cfg,
    read_cfg,
    read_pcfg,
    store_csg,
    read_csg,
    read_pcsg,
    add_rule!,
    remove_rule!,
    cleanup_removed_rules!

end # module HerbGrammar