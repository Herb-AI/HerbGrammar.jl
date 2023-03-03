
"""
Function for converting an `Expr` to a `ContextSensitiveGrammar` with probabilities.
If the expression is hardcoded, you should use the `@pcsgrammar` macro.
Only expressions in the correct format can be converted.
"""
function expr2pcsgrammar(ex::Expr)::ContextSensitiveGrammar
	cfg2csg(expr2pcfgrammar(ex))
end

"""
@pcsgrammar
Define a probabilistic grammar and return it as a ContextSensitiveGrammar. 
Syntax is identical to @pcfgrammar.
For example:
```julia-repl
grammar = @pcsgrammar begin
0.5 : R = x
0.3 : R = 1 | 2
0.2 : R = R + R
end
```
"""
macro pcsgrammar(ex)
	return expr2pcsgrammar(ex)
end