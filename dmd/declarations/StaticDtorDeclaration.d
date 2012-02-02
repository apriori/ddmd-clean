module dmd.declarations.StaticDtorDeclaration;

import dmd.Global;
import dmd.declarations.FuncDeclaration;
import dmd.VarDeclaration;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.HdrGenState;
import std.array;
import dmd.Identifier;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.Type;
import dmd.types.TypeFunction;
import dmd.Lexer;
import dmd.Statement;
import dmd.Expression;
import dmd.expressions.EqualExp;
import dmd.statements.DeclarationStatement;
import dmd.expressions.IdentifierExp;
import dmd.expressions.AddAssignExp;
import dmd.expressions.IntegerExp;
import dmd.Token;
import dmd.statements.IfStatement;
import dmd.statements.ReturnStatement;
import dmd.statements.CompoundStatement;
import dmd.Module;

import dmd.DDMDExtensions;

class StaticDtorDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	VarDeclaration vgate;	// 'gate' variable

    this(Loc loc, Loc endloc, string name = "_staticDtor")
	{
		super(loc, endloc, Identifier.uniqueId(name), STCstatic, null);
	    vgate = null;
	}
	
	override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		StaticDtorDeclaration sdd = new StaticDtorDeclaration(loc, endloc);
		return super.syntaxCopy(sdd);
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
			return;
		buf.put("static ~this()");
		bodyToCBuffer(buf, hgs);
	}

	override void toJsonBuffer(ref Appender!(char[]) buf)
	{
	}

	override StaticDtorDeclaration isStaticDtorDeclaration() { return this; }
}
