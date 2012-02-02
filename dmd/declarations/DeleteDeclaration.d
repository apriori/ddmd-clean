module dmd.declarations.DeleteDeclaration;

import dmd.Global;
import dmd.declarations.FuncDeclaration;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.Identifier;
import dmd.Parameter;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.types.TypeFunction;
import dmd.Type;

import dmd.DDMDExtensions;

class DeleteDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	Parameter[] arguments;

    this(Loc loc, Loc endloc, Parameter[] arguments)
	{
		super(loc, endloc, Id.classDelete, STCstatic, null);
		this.arguments = arguments;
	}
	
    override Dsymbol syntaxCopy(Dsymbol)
	{
		DeleteDeclaration f;

		f = new DeleteDeclaration(loc, endloc, null);

		FuncDeclaration.syntaxCopy(f);

		f.arguments = Parameter.arraySyntaxCopy(arguments);

		return f;
	}
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("delete");
		Parameter.argsToCBuffer(buf, hgs, arguments, 0);
		bodyToCBuffer(buf, hgs);
	}
	
    override string kind()
	{
		return "deallocator";
	}

    override bool isDelete()
	{
		return true;
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
	
version (_DH) {
    DeleteDeclaration isDeleteDeclaration() { return this; }
}
}
