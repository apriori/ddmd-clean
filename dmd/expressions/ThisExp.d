module dmd.expressions.ThisExp;

import dmd.Global;
import dmd.Expression;
import dmd.Declaration;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.Dsymbol;
import dmd.declarations.FuncDeclaration;
import dmd.InterState;
import dmd.Scope;
import dmd.Type;
import dmd.Token;
import dmd.HdrGenState;
import dmd.expressions.VarExp;


import std.array;
import dmd.DDMDExtensions;

class ThisExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Declaration var;

	this(Loc loc)
	{
		super(loc, TOKthis, ThisExp.sizeof);
		//printf("ThisExp::ThisExp() loc = %d\n", loc.linnum);
	}



	override bool isBool(bool result)
	{
		return result ? true : false;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("this");
	}





}

