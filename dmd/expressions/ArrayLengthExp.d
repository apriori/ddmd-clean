module dmd.expressions.ArrayLengthExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.IntegerExp;
import dmd.expressions.BinExp;
import dmd.expressions.UnaExp;
import dmd.InterState;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;
import dmd.Type;
import dmd.expressions.VarExp;
import dmd.VarDeclaration;
import dmd.expressions.PtrExp;
import dmd.Lexer;
import dmd.Identifier;
import dmd.initializers.ExpInitializer;
import dmd.expressions.DeclarationExp;
import dmd.expressions.CommaExp;
import dmd.expressions.AssignExp;
import dmd.expressions.AddrExp;



import std.array;
import dmd.DDMDExtensions;

class ArrayLengthExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1)
	{
		super(loc, TOKarraylength, ArrayLengthExp.sizeof, e1);
	}


	static Expression rewriteOpAssign(BinExp exp)
   {
        assert (false);
   } 


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.put(".length");
	}

}

