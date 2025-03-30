using Interfaces: @interface

components = (
    mandatory = (
        costs = ("all costs are `Real`s" =>  g -> eltype(costs(g)) <: Real),
    ),
    optional = (;)
)

description = """
Describes the interface for cost-based grammars within `HerbGrammar.jl`.
"""

@interface CostBasedInterface AbstractGrammar components description
