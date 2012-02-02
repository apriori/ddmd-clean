module dmd.types.TypePointer;

import dmd.Global;
import dmd.Type;
import dmd.Scope;
import dmd.types.TypeNext;
import dmd.HdrGenState;
import std.array;
import dmd.Expression;
import dmd.expressions.NullExp;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.varDeclarations.TypeInfoPointerDeclaration;


import dmd.DDMDExtensions;

class TypePointer : TypeNext
{
	mixin insertMemberExtension!(typeof(this));

    this(Type t)
	{
		super(Tpointer, t);
	}

    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		if (t == next)
			t = this;
		else
		{	
			t = new TypePointer(t);
			t.mod = mod;
		}
		return t;
	}
	
	
    override ulong size(Loc loc)
	{
		return PTRSIZE;
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		//printf("TypePointer::toCBuffer2() next = %d\n", next->ty);
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		next.toCBuffer2(buf, hgs, this.mod);
		if (next.ty != Tfunction)
			buf.put('*');
	}
	
	
    override bool isscalar()
	{
		return true;
	}
	
	
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoPointerDeclaration(this);
	}
	
	

}
