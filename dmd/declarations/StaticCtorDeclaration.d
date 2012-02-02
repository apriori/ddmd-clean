module dmd.declarations.StaticCtorDeclaration;

import dmd.Global;
import dmd.declarations.FuncDeclaration;
import dmd.Dsymbol;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.Identifier;
import dmd.types.TypeFunction;
import dmd.Type;
import dmd.Lexer;
import dmd.VarDeclaration;
import dmd.Expression;
import dmd.Statement;
import dmd.statements.DeclarationStatement;
import dmd.expressions.AddAssignExp;
import dmd.expressions.EqualExp;
import dmd.Token;
import dmd.statements.IfStatement;
import dmd.statements.CompoundStatement;
import dmd.Module;
import dmd.expressions.IntegerExp;
import dmd.statements.ReturnStatement;
import dmd.expressions.IdentifierExp;

import dmd.DDMDExtensions;

class StaticCtorDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Loc endloc, string name = "_staticCtor")
	{
		super(loc, endloc, Identifier.uniqueId("_staticCtor"), STCstatic, null);
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		StaticCtorDeclaration scd = new StaticCtorDeclaration(loc, endloc);
		return FuncDeclaration.syntaxCopy(scd);
	}
	
	
	override AggregateDeclaration isThis()
	{
		return null;
	}
	
	override bool isVirtual()
	{
		return false;
	}
	
	override bool addPreInvariant()
	{
		return false;
	}
	
	override bool addPostInvariant()
	{
		return false;
	}
	
	override void emitComment(Scope sc)
	{
	}
	
	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (hgs.hdrgen)
		{
			buf.put("static this();\n");
			return;
		}
		buf.put("static this()");
		bodyToCBuffer(buf, hgs);
	}

	override void toJsonBuffer(ref Appender!(char[]) buf)
	{
	}

	override StaticCtorDeclaration isStaticCtorDeclaration() { return this; }
}
