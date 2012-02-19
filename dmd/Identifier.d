module dmd.Identifier;

import dmd.BasicUtils;
import dmd.Token;

import std.array;
import std.conv;
import std.format;

Identifier[string] stringtable; 

void initKeywords()
{
    foreach ( k; dmd.Token.keywords )
    {  
        stringtable[k.name] = new Identifier( k.name, k.value );
    }
}

mixin( import("Id.txt"));

class Identifier
{
    TOK value;
    string string_;

    this(string string_, TOK value)
    {
        this.string_ = string_;
        this.value = value;
    }
    
    static void initKeywords()
    {
       foreach ( k; dmd.Token.keywords )
       {  
          stringtable[k.name] = new Identifier( k.name, k.value );
       }
    }

    override bool opEquals(Object o)
    {
       if (this is o) {
          return true;
		}

		if (auto i = cast(Identifier) o) {
			return string_ == i.string_;
		}

		return false;
	}

    hash_t hashCode()
    {
        assert(false);
    }

    void print()
    {
        //original... fprintf(stdmsg, "%s",string);
        assert(false);
    }

    string toChars()
    {
        return string_;
    }

    version (_DH) { string toHChars() { assert(false); } }

    string toHChars2()
    {
        string p;

        if (this == Id.ctor) p = "this";
        else if (this == Id.dtor) p = "~this";
        else if (this == Id.classInvariant) p = "invariant";
        else if (this == Id.unitTest) p = "unittest";
        else if (this == Id.dollar) p = "$";
        else if (this == Id.withSym) p = "with";
        else if (this == Id.result) p = "result";
        else if (this == Id.returnLabel) p = "return";
        else
        {
            p = toChars();
            if ( p[0] == '_')
            {
                if ( p == "_staticCtor")
                    p = "static this";
                else if ( p == "_staticDtor" )
                    p = "static ~this";
            }
        }
        return p;
    }

    DYNCAST dyncast()
    {
        return DYNCAST_IDENTIFIER;
    }

    static Identifier idPool(string s)
    {
        Identifier sv = stringtable.get( s, null );
        if ( sv is null )
            sv = new Identifier( s, TOKidentifier ); 
        return sv;
    }

    static Identifier uniqueId(string s)
    {
        static uint num = 0;
        num++;
        return uniqueId(s, num);
    }

    /*********************************************
     * Create a unique identifier using the prefix s.
     */
    static Identifier uniqueId(string s, int num)
    {
        string buffer = s ~ to!string(num);
        assert ( buffer.length + ( 3 * int.sizeof ) + 1 <= 32 );
        return idPool( buffer );
    }

}

