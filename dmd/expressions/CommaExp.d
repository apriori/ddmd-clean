module dmd.expressions.CommaExp;

import dmd.Global;
import dmd.expressions.BinExp;
import dmd.Scope;
import dmd.expressions.DeclarationExp;
import dmd.expressions.VarExp;
import dmd.VarDeclaration;
import dmd.Expression;
import dmd.Token;
import dmd.Type;
import dmd.InterState;


import dmd.DDMDExtensions;

class CommaExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{

		super(loc, TOKcomma, CommaExp.sizeof, e1, e2);
	}

}
