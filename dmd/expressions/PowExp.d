module dmd.expressions.PowExp;

import dmd.Global;
import dmd.expressions.BinExp;
import dmd.Scope;
import dmd.Identifier;
import dmd.Expression;
import dmd.Token;
import dmd.Module;
import dmd.expressions.IdentifierExp;
import dmd.expressions.DotIdExp;
import dmd.expressions.CallExp;
import dmd.expressions.ErrorExp;
import dmd.expressions.CommaExp;
import dmd.expressions.AndExp;
import dmd.expressions.CondExp;
import dmd.expressions.IntegerExp;
import dmd.Type;
import dmd.Dsymbol;
import dmd.Lexer;
import dmd.VarDeclaration;
import dmd.initializers.ExpInitializer;
import dmd.expressions.VarExp;
import dmd.expressions.DeclarationExp;
import dmd.expressions.MulExp;

import dmd.DDMDExtensions;


class PowExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
    {
        super(loc, TOKpow, PowExp.sizeof, e1, e2);
    }
        
   

    // For operator overloading
    override Identifier opId()
    {
        return Id.pow;
    }
    
    override Identifier opId_r()
    {
        return Id.pow_r;
    }
}

