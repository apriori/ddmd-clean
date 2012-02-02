module dmd.conditions.DebugCondition;

import dmd.Global;
import dmd.conditions.DVCondition;
import dmd.Module;
import dmd.Identifier;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.HdrGenState;
import std.array;

import dmd.DDMDExtensions;

class DebugCondition : DVCondition
{
	mixin insertMemberExtension!(typeof(this));

    static void setGlobalLevel(uint level)
	{
		assert(false);
	}
	
    static void addGlobalIdent(const(char)* ident)
	{
		assert(false);
	}
	
    static void addPredefinedGlobalIdent(const(char)* ident)
	{
		assert(false);
	}

    this(Module mod, uint level, Identifier ident)
	{
		super(mod, level, ident);
	}

    override bool include(Scope sc, ScopeDsymbol s)
	{
		//printf("DebugCondition::include() level = %d, debuglevel = %d\n", level, global.params.debuglevel);
		if (inc == 0)
		{
			inc = 2;

			if (ident)
			{
				if ( null !is (ident.toChars() in mod.debugids) )
					inc = 1;
				else if ( null !is (ident.toChars() in global.params.debugids ) )
					inc = 1;
				else
				{	
					mod.debugidsNot[ident.toChars()] = true;
				}
			}
			else if (level <= global.params.debuglevel || level <= mod.debuglevel)
				inc = 1;
		}

		return (inc == 1);
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
}
