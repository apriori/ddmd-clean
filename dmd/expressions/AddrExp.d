module dmd.expressions.AddrExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.UnaExp;
import dmd.Type;
import dmd.Scope;
import dmd.expressions.ErrorExp;
import dmd.expressions.DotVarExp;
import dmd.declarations.FuncDeclaration;
import dmd.expressions.DelegateExp;
import dmd.expressions.VarExp;
import dmd.VarDeclaration;
import dmd.expressions.ThisExp;
import dmd.Token;
import dmd.expressions.CommaExp;
import dmd.expressions.PtrExp;
import dmd.expressions.SymOffExp;
import dmd.expressions.IndexExp;
import dmd.expressions.OverExp;
import dmd.Dsymbol;
import dmd.ScopeDsymbol;
import dmd.types.TypeSArray;


import dmd.DDMDExtensions;

class AddrExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		super(loc, TOKaddress, AddrExp.sizeof, e);
	}


    



}

