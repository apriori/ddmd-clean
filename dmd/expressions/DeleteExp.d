module dmd.expressions.DeleteExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.UnaExp;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Type;
import dmd.expressions.IndexExp;
import dmd.expressions.VarExp;
import dmd.Identifier;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.Lexer;
import dmd.declarations.FuncDeclaration;
import dmd.types.TypeStruct;
import dmd.expressions.CallExp;
import dmd.expressions.DotVarExp;
import dmd.expressions.DeclarationExp;
import dmd.initializers.ExpInitializer;
import dmd.VarDeclaration;
import dmd.types.TypePointer;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.types.TypeClass;
import dmd.Token;
import dmd.types.TypeAArray;
import dmd.types.TypeSArray;


import std.array;
import dmd.DDMDExtensions;

class DeleteExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		super(loc, TOKdelete, DeleteExp.sizeof, e);
	}


	override Expression checkToBoolean()
	{
		assert(false);
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("delete ");
		expToCBuffer(buf, hgs, e1, precedence[op]);
	}

}

