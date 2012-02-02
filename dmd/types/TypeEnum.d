module dmd.types.TypeEnum;

import dmd.Global;
import std.format;

import dmd.Type;
import dmd.scopeDsymbols.EnumDeclaration;
import dmd.Scope;
import dmd.expressions.ErrorExp;
import dmd.Dsymbol;
import dmd.dsymbols.EnumMember;
import dmd.HdrGenState;
import std.array;
import dmd.Expression;
import dmd.Identifier;
import std.array;
import dmd.expressions.StringExp;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.varDeclarations.TypeInfoEnumDeclaration;


import dmd.DDMDExtensions;

class TypeEnum : Type
{
	mixin insertMemberExtension!(typeof(this));

    EnumDeclaration sym;

    this(EnumDeclaration sym)
	{
		super(Tenum);
		this.sym = sym;
	}
	
    override Type syntaxCopy()
	{
		assert(false);
	}
	
    override ulong size(Loc loc)
	{
		if (!sym.memtype)
		{
			error(loc, "enum %s is forward referenced", sym.toChars());
			return 4;
		}
		return sym.memtype.size(loc);
	}
	
	override uint alignsize()
	{
		if (!sym.memtype)
		{
			debug writef("1: ");

			error(Loc(0), "enum %s is forward referenced", sym.toChars());
			return 4;
		}
		return sym.memtype.alignsize();
	}

	override string toChars()
	{
		if (mod)
			return super.toChars();
		return sym.toChars();
	}
	
	
	
    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		string name = sym.mangle();
		Type.toDecoBuffer(buf, flag);
		formattedWrite(buf,"%s", name);
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		buf.put(sym.toChars());
	}

	
	
    override bool isintegral()
	{
	    return sym.memtype.isintegral();
	}
	
    override bool isfloating()
	{
	    return sym.memtype.isfloating();
	}
	
    override bool isreal()
	{
		return sym.memtype.isreal();
	}
	
    override bool isimaginary()
	{
		return sym.memtype.isimaginary();
	}
	
    override bool iscomplex()
	{
		return sym.memtype.iscomplex();
	}
	
    override bool checkBoolean()
	{
		return sym.memtype.checkBoolean();
	}
	
    override bool isAssignable()
	{
		return sym.memtype.isAssignable();
	}
	
    override bool isscalar()
	{
	    return sym.memtype.isscalar();
	}
	
    override bool isunsigned()
	{
		return sym.memtype.isunsigned();
	}
	
	
	
	
	
	
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoEnumDeclaration(this);
	}
	
	

}
