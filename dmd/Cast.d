module dmd.Cast;

import dmd.Global;
import dmd.Expression;
import dmd.Type;
import dmd.expressions.IntegerExp;
import dmd.expressions.RealExp;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.Dsymbol;
import dmd.VarDeclaration;
import dmd.expressions.StructLiteralExp;
import dmd.Token;

Expression expType(Type type, Expression e)
{
    if (type !is e.type)
    {
		e.type = type;
    }
    return e;
}

