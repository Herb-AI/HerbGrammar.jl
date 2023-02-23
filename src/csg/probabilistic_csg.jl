
"""
Function for converting an `Expr` to a `ContextSensitiveGrammar` with probabilities.
If the expression is hardcoded, you should use the `@pcsgrammar` macro.
Only expressions in the correct format can be converted.
"""
function expr2pcsgrammar(ex::Expr)::ContextSensitiveGrammar
	cfg2csg(expr2pcfgrammar(ex))
end

macro pcsgrammar(ex)
	return expr2pcsgrammar(ex)
end