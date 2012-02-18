module dmd.types.TypeAArray;

import dmd.Global;
import dmd.types.TypeArray;
import dmd.TypeInfoDeclaration;
import dmd.Expression;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.Dsymbol;
import dmd.Type;
import dmd.types.TypeSArray;
import dmd.HdrGenState;
import std.array;
import dmd.Identifier;
import dmd.FuncDeclaration;
import dmd.types.TypeFunction;



class TypeAArray : TypeArray
{
    Type	index;		// key type
    Loc		loc;
    Scope	sc;
    StructDeclaration impl;	// implementation

    this(Type t, Type index)
	{
		super(Taarray, t);
		this.index = index;
	}
	
    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		Type ti = index.syntaxCopy();
		if (t == next && ti == index)
			t = this;
		else
		{	
			t = new TypeAArray(t, ti);
			t.mod = mod;
		}
		return t;
	}

    override ulong size(Loc loc)
	{
		return PTRSIZE /* * 2*/;
	}
	
    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		index.toDecoBuffer(buf);
		next.toDecoBuffer(buf, (flag & 0x100) ? MODundefined : mod);
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		next.toCBuffer2(buf, hgs, this.mod);
		buf.put('[');
		index.toCBuffer2(buf, hgs, MODundefined);
		buf.put(']');
	}
	
	
	
	
	
    override bool checkBoolean()
	{
		return true;
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoAssociativeArrayDeclaration(this);
	}
	
	
	
	
}
