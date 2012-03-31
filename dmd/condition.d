module dmd.condition;

import dmd.global;
import dmd.expression;
import dmd.Scope;
import dmd.scopeDsymbol;
import dmd.hdrGenState;
import dmd.identifier;
import dmd.Module;

import std.array;
import std.string : startsWith, formattedWrite;

class Condition 
{
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

class DVCondition : Condition
{
    uint level;
    Identifier ident;
    Module mod;

    this(Module mod, uint level, Identifier ident)
	{
		super(Loc(0));
		this.mod = mod;
		this.level = level;
		this.ident = ident;
	}

    override Condition syntaxCopy()
	{
		return this;	// don't need to copy
	}

    bool include(Scope sc, ScopeDsymbol s) { assert(false); }

    
}

class DebugCondition : DVCondition
{
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

class StaticIfCondition : Condition
{
	Expression exp;

	this(Loc loc, Expression exp)
	{
		super(loc);
		this.exp = exp;
	}

	override Condition syntaxCopy()
	{
	    return new StaticIfCondition(loc, exp.syntaxCopy());
	}

   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      buf.put("static if(");
      exp.toCBuffer(buf, hgs);
      buf.put(')');
   }
}

class VersionCondition : DVCondition
{
    static void setGlobalLevel(uint level)
    {
        global.params.versionlevel = level;
    }

    static void checkPredefined(Loc loc, string ident)
    {
        enum string[] reserved = [
            "DigitalMars", "X86", "X86_64",
            "Windows", "Win32", "Win64",
            "linux",
            /* Although Posix is predefined by D1, disallowing its
             * redefinition breaks makefiles and older builds.
             */
            "Posix",
            "D_NET",
            "OSX", "FreeBSD",
            "Solaris",
            "LittleEndian", "BigEndian",
            "all",
            "none",
            ];

        foreach (reservedIdent; reserved)
        {
            if (ident == reservedIdent)
                goto Lerror;
        }

        if (ident.startsWith("D_")) {
            goto Lerror;
        }

        return;

    Lerror:
        error(loc, "version identifier '%s' is reserved and cannot be set", ident);
    }

    static void addGlobalIdent(string ident)
    {
        checkPredefined(Loc(0), ident);
        addPredefinedGlobalIdent(ident);
    }

    static void addPredefinedGlobalIdent(string ident)
    {
        global.params.versionids[ident] = true;	///
    }

    this( Module mod, uint level, Identifier ident )
    {
        super(mod, level, ident);
    }

    override final bool include( Scope sc, ScopeDsymbol s )
    {
        //printf("VersionCondition::include() level = %d, versionlevel = %d\n", level, global.params.versionlevel);
        //if (ident) printf("\tident = '%s'\n", ident->toChars());
        if (inc == 0) 
        {
            inc = 2;
            if ( ident !is null ) 
            {
                if ( (ident.toChars() in mod.versionids) !is null )
                    inc = 1; 
                else if ( (ident.toChars() in global.params.versionids) !is null )
                    inc = 1;  
                else 
                    mod.versionidsNot[ ident.toChars() ] = true;
            } 
            else if (level <= global.params.versionlevel || level <= mod.versionlevel) {
                inc = 1;
            }
        }

        return (inc == 1);
   } 

    override final void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
    {
        if (ident !is null) 
        {
            formattedWrite(buf,"version(%s)", ident.toChars());
        } 
        else 
        {
            formattedWrite(buf,"version(%u)", level);
        }
    }
}
