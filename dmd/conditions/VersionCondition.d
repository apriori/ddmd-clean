module dmd.conditions.VersionCondition;

import dmd.Global;
import std.format;

import dmd.conditions.DVCondition;
import dmd.Module;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.HdrGenState;
import std.array;
import dmd.Identifier;

import std.string : startsWith;

import std.stdio;

import dmd.DDMDExtensions;

// This is no longer necessary with Associative arrays
bool findCondition( bool[string] ids, Identifier ident) 
{ return null !is (ident.toChars() in ids); 
}

class VersionCondition : DVCondition
{
    mixin insertMemberExtension!(typeof(this));

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
        if (ident !is null) {
            formattedWrite(buf,"version (%s)", ident.toChars());
        } else {
            formattedWrite(buf,"version (%u)", level);
        }
    }
}
