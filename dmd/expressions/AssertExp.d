module dmd.expressions.AssertExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.UnaExp;
import dmd.InterState;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Type;
import dmd.declarations.InvariantDeclaration;
import dmd.Token;
import dmd.expressions.AddrExp;
import dmd.expressions.DotVarExp;
import dmd.types.TypeClass;
import dmd.Module;
import dmd.declarations.FuncDeclaration;
import dmd.expressions.HaltExp;
import dmd.types.TypeStruct;


import std.string : toStringz;

import std.array;
import dmd.DDMDExtensions;

//static __gshared Symbol* assertexp_sfilename = null;
//static __gshared string assertexp_name = null;
//static __gshared Module assertexp_mn = null;

class AssertExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	Expression msg;

	this(Loc loc, Expression e, Expression msg = null)
	{

		super(loc, TOKassert, AssertExp.sizeof, e);
		this.msg = msg;
	}

	override Expression syntaxCopy()
	{
		AssertExp ae = new AssertExp(loc, e1.syntaxCopy(),
				       msg ? msg.syntaxCopy() : null);
		return ae;
	}




	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("assert(");
		expToCBuffer(buf, hgs, e1, PREC_assign);
		if (msg)
		{
			buf.put(',');
			expToCBuffer(buf, hgs, msg, PREC_assign);
		}
	}





}

