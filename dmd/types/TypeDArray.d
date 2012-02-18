module dmd.types.TypeDArray;

import dmd.Global;
import dmd.types.TypeArray;
import dmd.Token;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.Expression;
import dmd.Identifier;
import dmd.TypeInfoDeclaration;
import dmd.types.TypeStruct;
import dmd.types.TypePointer;


// Dynamic array, no dimension
class TypeDArray : TypeArray
{
    this(Type t)
	{
		super(Tarray, t);
		//printf("TypeDArray(t = %p)\n", t);
	}
	
    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		if (t == next)
			t = this;
		else
		{	
			t = new TypeDArray(t);
			t.mod = mod;
		}
		return t;
	}
	
    override ulong size(Loc loc)
	{
		//printf("TypeDArray.size()\n");
		return PTRSIZE * 2;
	}
	
    override uint alignsize()
	{
		// A DArray consists of two ptr-sized values, so align it on pointer size
		// boundary
		return PTRSIZE;
	}
	
	
    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		if (next)
			next.toDecoBuffer(buf, (flag & 0x100) ? 0 : mod);
	}
	
	override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{
			toCBuffer3(buf, hgs, mod);
			return;
		}
		if (equals(global.tstring))
			buf.put("string");
		else
		{
			next.toCBuffer2(buf, hgs, this.mod);
			buf.put("[]");
		}
	}
	
	
	
	
    override bool checkBoolean()
	{
		return true;
	}
	
	
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoArrayDeclaration(this);
	}



}
