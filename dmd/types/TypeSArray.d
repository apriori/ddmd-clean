module dmd.types.TypeSArray;

import dmd.Global;
import std.format;

import dmd.types.TypeArray;
import dmd.varDeclarations.TypeInfoStaticArrayDeclaration;
import dmd.types.TypeAArray;
import dmd.expressions.ArrayExp;
import dmd.Parameter;
import dmd.types.TypeIdentifier;
import dmd.TemplateParameter;
import dmd.templateParameters.TemplateValueParameter;
import dmd.types.TypeStruct;
import dmd.types.TypeTuple;
import dmd.expressions.VarExp;
import dmd.expressions.IntegerExp;
import dmd.Expression;
import dmd.Type;
import dmd.declarations.TupleDeclaration;
import dmd.Token;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.HdrGenState;
import std.array;
import dmd.Identifier;
import dmd.types.TypeDArray;
import dmd.types.TypePointer;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.ScopeDsymbol;
import dmd.scopeDsymbols.ArrayScopeSymbol;
import dmd.expressions.IndexExp;

import dmd.DDMDExtensions;

// Static array, one with a fixed dimension
class TypeSArray : TypeArray
{
	mixin insertMemberExtension!(typeof(this));

    Expression dim;

    this(Type t, Expression dim)
	{
		super(Tsarray, t);
		//printf("TypeSArray(%s)\n", dim.toChars());
		this.dim = dim;
	}
	
    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		Expression e = dim.syntaxCopy();
		t = new TypeSArray(t, e);
		t.mod = mod;
		return t;
	}

    override ulong size(Loc loc)
	{
		if (!dim)
			return Type.size(loc);

		long sz = dim.toInteger();

		{	
			long n, n2;
			n = next.size();
			n2 = n * sz;
			if (n && (n2 / n) != sz)
				goto Loverflow;

			sz = n2;
		}
		return sz;

	Loverflow:
		error(loc, "index %jd overflow for static array", sz);
		return 1;
	}
	
    override uint alignsize()
	{
		return next.alignsize();
	}



    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		if (dim)
			//buf.printf("%ju", dim.toInteger());	///
			formattedWrite(buf,"%s", dim.toInteger());
		if (next)
			/* Note that static arrays are value types, so
			 * for a parameter, propagate the 0x100 to the next
			 * level, since for T[4][3], any const should apply to the T,
			 * not the [4].
			 */
			next.toDecoBuffer(buf,  (flag & 0x100) ? flag : mod);
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		next.toCBuffer2(buf, hgs, this.mod);
		formattedWrite(buf,"[%s]", dim.toChars());
	}
	
	
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoStaticArrayDeclaration(this);
	}
	
	
	

	
}
