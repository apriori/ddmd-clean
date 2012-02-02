module dmd.Catch;

import dmd.Global;
import dmd.Type;
import dmd.Scope;
import dmd.Identifier;
import dmd.VarDeclaration;
import dmd.Statement;
import dmd.types.TypeIdentifier;
import dmd.ScopeDsymbol;
import dmd.HdrGenState;

import dmd.DDMDExtensions;

import std.array;

class Catch 
{
	mixin insertMemberExtension!(typeof(this));

    Loc loc;
    Type type;
    Identifier ident;
    VarDeclaration var = null;
    Statement handler;

    this(Loc loc, Type t, Identifier id, Statement handler)
	{
		//printf("Catch(%s, loc = %s)\n", id.toChars(), loc.toChars());
		this.loc = loc;
		this.type = t;
		this.ident = id;
		this.handler = handler;
	}

    Catch syntaxCopy()
	{
		Catch c = new Catch(loc, (type ? type.syntaxCopy() : null), ident, (handler ? handler.syntaxCopy() : null));
		return c;
	}

    void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("catch");
		if (type)
		{   
			buf.put('(');
			type.toCBuffer(buf, ident, hgs);
			buf.put(')');
		}
		buf.put('\n');
		buf.put('{');
		buf.put('\n');
		if (handler)
			handler.toCBuffer(buf, hgs);
		buf.put('}');
		buf.put('\n');
	}
}
