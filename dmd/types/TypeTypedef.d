module dmd.types.TypeTypedef;

import dmd.Global;
import std.format;

import dmd.Type;
import dmd.declarations.TypedefDeclaration;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.Expression;
import dmd.Identifier;
import dmd.types.TypeSArray;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.varDeclarations.TypeInfoTypedefDeclaration;

import dmd.DDMDExtensions;

class TypeTypedef : Type
{
	mixin insertMemberExtension!(typeof(this));

    TypedefDeclaration sym;

    this(TypedefDeclaration sym)
	{
		super(Ttypedef);
		this.sym = sym;
	}
	
    override Type syntaxCopy()
	{
		assert(false);
	}
	
    override ulong size(Loc loc)
	{
		return sym.basetype.size(loc);
	}
	
    override uint alignsize()
	{
		assert(false);
	}
	
    override string toChars()
	{
		assert(false);
	}
	
    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		string name = sym.mangle();
		formattedWrite(buf,"%s", name);
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		//printf("TypeTypedef.toCBuffer2() '%s'\n", sym.toChars());
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		
		buf.put(sym.toChars());
	}
	
	
	
    bool isbit()
	{
		assert(false);
	}
	
    override bool isintegral()
	{
		//printf("TypeTypedef::isintegral()\n");
		//printf("sym = '%s'\n", sym->toChars());
		//printf("basetype = '%s'\n", sym->basetype->toChars());
		return sym.basetype.isintegral();
	}
	
    override bool isfloating()
	{
		return sym.basetype.isfloating();
	}
	
    override bool isreal()
	{
		return sym.basetype.isreal();
	}
	
    override bool isimaginary()
	{
		return sym.basetype.isimaginary();
	}
	
    override bool iscomplex()
	{
		return sym.basetype.iscomplex();
	}
	
    override bool isscalar()
	{
		return sym.basetype.isscalar();
	}
	
    override bool isunsigned()
	{
		return sym.basetype.isunsigned();
	}
	
    override bool checkBoolean()
	{
		return sym.basetype.checkBoolean();
	}
	
    override bool isAssignable()
	{
		return sym.basetype.isAssignable();
	}

    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoTypedefDeclaration(this);
	}
}
