module dmd.types.TypeIdentifier;

import dmd.Global;
import std.format;

import dmd.types.TypeQualified;
import dmd.Identifier;
import dmd.expressions.IdentifierExp;
import dmd.expressions.DotIdExp;
import dmd.types.TypeTypedef;
import dmd.HdrGenState;
import std.array;
import dmd.Expression;
import dmd.Scope;
import dmd.Type;
import dmd.Dsymbol;


import dmd.DDMDExtensions;

class TypeIdentifier : TypeQualified
{
	mixin insertMemberExtension!(typeof(this));

    Identifier ident;

    this(Loc loc, Identifier ident)
	{
		super(Tident, loc);
		this.ident = ident;
	}
	
    override Type syntaxCopy()
	{
		TypeIdentifier t = new TypeIdentifier(loc, ident);
		t.mod = mod;

		return t;
	}
	
    //char *toChars();
	
    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		string name = ident.toChars();
		formattedWrite(buf,"%d%s", name.length, name);
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		buf.put(this.ident.toChars());
		toCBuffer2Helper(buf, hgs);
	}

	/*************************************
	 * Takes an array of Identifier[] and figures out if
	 * it represents a Type or an Expression.
	 * Output:
	 *	if expression, *pe is set
	 *	if type, *pt is set
	 */
	
	/*****************************************
	 * See if type resolves to a symbol, if so,
	 * return that symbol.
	 */
	
	
	
    override Type reliesOnTident()
	{
		return this;
	}
	
}
