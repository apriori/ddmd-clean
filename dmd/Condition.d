module dmd.Condition;

import dmd.Global;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.HdrGenState;
import std.array;

import dmd.DDMDExtensions;

class Condition 
{
	mixin insertMemberExtension!(typeof(this));

    Loc loc;
    int inc = 0;// 0: not computed yet
				// 1: include
				// 2: do not include

    this(Loc loc)
	{
		this.loc = loc;
	}

    abstract Condition syntaxCopy();
    abstract void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs);
    
    bool include(Scope sc, ScopeDsymbol s)
    {
        assert( false );
    }
}
