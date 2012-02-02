module dmd.types.TypeDelegate;

import dmd.Global;
import dmd.Type;
import dmd.types.TypeNext;
import std.array;
import dmd.expressions.AddExp;
import dmd.expressions.PtrExp;
import dmd.expressions.IntegerExp;
import dmd.expressions.NullExp;
import dmd.types.TypeFunction;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.Identifier;
import dmd.Parameter;
import dmd.Scope;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.varDeclarations.TypeInfoDelegateDeclaration;


import dmd.DDMDExtensions;

class TypeDelegate : TypeNext
{
	mixin insertMemberExtension!(typeof(this));

    // .next is a TypeFunction

    this(Type t)
	{
		super(Tfunction, t);
		ty = Tdelegate;
	}
	
    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		if (t == next)
			t = this;
		else
		{	
			t = new TypeDelegate(t);
			t.mod = mod;
		}
		return t;
	}
	
	
    override ulong size(Loc loc)
	{
		return PTRSIZE * 2;
	}
	
    
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		TypeFunction tf = cast(TypeFunction)next;

		tf.next.toCBuffer2(buf, hgs, MODundefined);
		buf.put(" delegate");
		Parameter.argsToCBuffer(buf, hgs, tf.parameters, tf.varargs);
	}
	
	
	
    override bool checkBoolean()
	{
		return true;
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoDelegateDeclaration(this);
	}
	
	


}
