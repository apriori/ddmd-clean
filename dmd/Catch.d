module dmd.Catch;

import dmd.global;
import dmd.type;
import dmd.Scope;
import dmd.identifier;
import dmd.varDeclaration;
import dmd.statement;
//import dmd.types.TypeIdentifier;
import dmd.scopeDsymbol;
import dmd.hdrGenState;


import std.array;

class Catch 
{
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
