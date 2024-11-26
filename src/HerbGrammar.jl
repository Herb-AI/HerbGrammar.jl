module HerbGrammar

import TreeView: walk_tree
using DataStructures # NodeRecycler
using Serialization # grammar_io

using HerbCore

include("grammar_base.jl")
include("utils.jl")
include("nodelocation.jl")

include("csg/csg.jl")
include("csg/probabilistic_csg.jl")

include("rulenode_operators.jl")

include("grammar_io.jl")

export 
    ContextSensitiveGrammar,
    AbstractRuleNode,
    RuleNode,
    Hole,
    NodeLoc,

    @cfgrammar,
    max_arity,
    isterminal,
    iseval,
    log_probability,
    probability,
    isprobabilistic,
    isvariable,
    return_type,
    contains_returntype,
    nchildren,
    child_types,
    get_domain,
    get_childtypes,
    nonterminals,
    iscomplete,
    parse_rule!,

    @csgrammar,
    expr2csgrammar,
    clearconstraints!,
    addconstraint!,
    merge_grammars!,
    expr2rulenode,

    @pcfgrammar,

    @pcsgrammar,
    expr2pcsgrammar,

    SymbolTable,
    grammar2symboltable,
    
    rulenode2expr,
    rulenode_log_probability,

    mindepth_map,
    mindepth,
    containedin,
    subsequenceof,
    store_csg,
    read_csg,
    read_pcsg,
    add_rule!,
    remove_rule!,
    cleanup_removed_rules!,
    holes_from_child_types,
    rulenode_with_empty_children,
    uniform_hole_with_empty_children

end # module HerbGrammar
