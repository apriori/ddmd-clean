module dmd.declarations.CtorDeclaration;

import dmd.Global;
import dmd.declarations.FuncDeclaration;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.types.TypeFunction;
import dmd.Type;
import dmd.Expression;
import dmd.expressions.ThisExp;
import dmd.Statement;
import dmd.statements.ReturnStatement;
import dmd.statements.CompoundStatement;
import dmd.Parameter;
import dmd.Identifier;

import dmd.DDMDExtensions;

class CtorDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	Parameter[] arguments;
    int varargs;

    this(Loc loc, Loc endloc, Parameter[] arguments, int varargs)
	{
		super(loc, endloc, Id.ctor, STCundefined, null);
		
		this.arguments = arguments;
		this.varargs = varargs;
		//printf("CtorDeclaration(loc = %s) %s\n", loc.toChars(), toChars());
	}
	
    override Dsymbol syntaxCopy(Dsymbol)
	{
		CtorDeclaration f = new CtorDeclaration(loc, endloc, null, varargs);

		f.outId = outId;
		f.frequire = frequire ? frequire.syntaxCopy() : null;
		f.fensure  = fensure  ? fensure.syntaxCopy()  : null;
		f.fbody    = fbody    ? fbody.syntaxCopy()    : null;
		assert(!fthrows); // deprecated

		f.arguments = Parameter.arraySyntaxCopy(arguments);
		return f;
	}
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

    override string kind()
	{
		return "constructor";
	}
	
    override string toChars()
	{
		return "this";
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
		return (isThis() && vthis && global.params.useInvariants);
	}
	
    override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}

    override CtorDeclaration isCtorDeclaration() { return this; }
}
