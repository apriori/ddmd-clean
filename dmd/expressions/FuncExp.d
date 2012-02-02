module dmd.expressions.FuncExp;

import dmd.Global;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.HdrGenState;
import dmd.declarations.FuncLiteralDeclaration;
import dmd.Token;
import dmd.types.TypeFunction;
import dmd.types.TypeDelegate;
import dmd.Type;


import std.array;
import dmd.DDMDExtensions;

class FuncExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	FuncLiteralDeclaration fd;

	this(Loc loc, FuncLiteralDeclaration fd)
	{
		super(loc, TOKfunction, FuncExp.sizeof);
		this.fd = fd;
	}

	override Expression syntaxCopy()
	{
		return new FuncExp(loc, cast(FuncLiteralDeclaration)fd.syntaxCopy(null));
	}

	


	override string toChars()
	{
		return fd.toChars();
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		fd.toCBuffer(buf, hgs);
		//buf.put(fd.toChars());
	}


}

