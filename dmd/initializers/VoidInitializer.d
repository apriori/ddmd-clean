module dmd.initializers.VoidInitializer;

import dmd.Global;
import dmd.Initializer;
import dmd.Type;
import dmd.Scope;
import dmd.Expression;
import dmd.HdrGenState;
import std.array;


import dmd.DDMDExtensions;

class VoidInitializer : Initializer
{
	mixin insertMemberExtension!(typeof(this));

    Type type = null;		// type that this will initialize to

    this(Loc loc)
	{
		super(loc);
	}
	
    override Initializer syntaxCopy()
	{
		return new VoidInitializer(loc);
	}
	
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("void");
	}


    override VoidInitializer isVoidInitializer() { return this; }
}
