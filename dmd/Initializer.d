module dmd.Initializer;

import dmd.Global;
import dmd.Scope;
import dmd.Type;
import dmd.Expression;
import dmd.HdrGenState;
import std.array;
import dmd.initializers.VoidInitializer;
import dmd.initializers.StructInitializer;
import dmd.initializers.ArrayInitializer;
import dmd.initializers.ExpInitializer;

import dmd.DDMDExtensions;

class Initializer
{
	mixin insertMemberExtension!(typeof(this));

    Loc loc;

    this(Loc loc)
	{
		this.loc = loc;
	}
	
    Initializer syntaxCopy()
	{
		return this;
	}
	
	Expression toExpression() { assert(false); }
	
   string toChars()
	{
		auto buf = appender!(char[])();
		HdrGenState hgs;

		toCBuffer(buf, hgs);
		return buf.data.idup;
	}
	
	abstract void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs);
	


	VoidInitializer isVoidInitializer() { return null; }
	
    StructInitializer isStructInitializer()  { return null; }
    
	ArrayInitializer isArrayInitializer()  { return null; }
    
	ExpInitializer isExpInitializer()  { return null; }
}
