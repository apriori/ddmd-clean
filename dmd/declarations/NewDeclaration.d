module dmd.declarations.NewDeclaration;

import dmd.Global;
import dmd.declarations.FuncDeclaration;
import dmd.Dsymbol;
import dmd.Parameter;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.Type;
import dmd.types.TypeFunction;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.Identifier;

import dmd.DDMDExtensions;

class NewDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	Parameter[] arguments;
    int varargs;

    this(Loc loc, Loc endloc, Parameter[] arguments, int varargs)
	{
		super(loc, endloc, Id.classNew, STCstatic, null);
		this.arguments = arguments;
		this.varargs = varargs;
	}

    override Dsymbol syntaxCopy(Dsymbol)
	{
		NewDeclaration f;

		f = new NewDeclaration(loc, endloc, null, varargs);

		FuncDeclaration.syntaxCopy(f);

		f.arguments = Parameter.arraySyntaxCopy(arguments);

		return f;
	}


    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("new");
		Parameter.argsToCBuffer(buf, hgs, arguments, varargs);
		bodyToCBuffer(buf, hgs);
	}

    override string kind()
	{
		return "allocator";
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

    override NewDeclaration isNewDeclaration() { return this; }
}
