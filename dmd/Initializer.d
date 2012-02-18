module dmd.Initializer;

import dmd.Global;
import dmd.Scope;
import dmd.Type;
import dmd.Expression;
import dmd.HdrGenState;
import dmd.Identifier;
import dmd.ScopeDsymbol;
import dmd.VarDeclaration;
import std.array;

class Initializer
{
    Loc loc;

    this(Loc loc)
	{
		this.loc = loc;
	}
	
    Initializer syntaxCopy()
	{
		return this;
	}
	
	Expression toExpression() { assert(false); }
	
   string toChars()
	{
		auto buf = appender!(char[])();
		HdrGenState hgs;

		toCBuffer(buf, hgs);
		return buf.data.idup;
	}
	
	abstract void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs);
	


	VoidInitializer isVoidInitializer() { return null; }
	
    StructInitializer isStructInitializer()  { return null; }
    
	ArrayInitializer isArrayInitializer()  { return null; }
    
	ExpInitializer isExpInitializer()  { return null; }
}

class ArrayInitializer : Initializer
{
    Expression[] index;	// indices
    Initializer[] value;	// of Initializer *'s
    uint dim = 0;		// length of array being initialized
    Type type = null;	// type that array will be used to initialize
    int sem = 0;		// !=0 if semantic() is run

    this(Loc loc)
	{
		super(loc);
	}
	
    override Initializer syntaxCopy()
	{
		//printf("ArrayInitializer.syntaxCopy()\n");

		ArrayInitializer ai = new ArrayInitializer(loc);

		assert(index.length == value.length);
		ai.index.reserve(index.length);
		ai.value.reserve(value.length);
		for (int i = 0; i < ai.value.length; i++)
		{	
			Expression e = index[i];
			if (e)
				e = e.syntaxCopy();
			ai.index[i] = e;

			auto init = value[i];
			init = init.syntaxCopy();
			ai.value[i] = init;
		}
		return ai;
	}
	
    void addInit(Expression index, Initializer value)
	{
		this.index ~= (index);
		this.value ~= (value);
		dim = 0;
		type = null;
	}
	
	
    int isAssociativeArray()
    {
        for (size_t i = 0; i < value.length; i++)
        {
	        if (index[i])
	            return 1;
        }
        return 0;
    }
    

	/********************************
	 * If possible, convert array initializer to array literal.
	  * Otherwise return null.
	 */	

	/********************************
	 * If possible, convert array initializer to associative array initializer.
	 */
	
	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

	

    override ArrayInitializer isArrayInitializer() { return this; }
}

class ExpInitializer : Initializer
{
    Expression exp;

    this(Loc loc, Expression exp)
	{
		super(loc);
		this.exp = exp;
	}
	
    override Initializer syntaxCopy()
	{
		return new ExpInitializer(loc, exp.syntaxCopy());
	}
	
	
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		exp.toCBuffer(buf, hgs);
	}


    override ExpInitializer isExpInitializer() { return this; }
}

class StructInitializer : Initializer
{
    Identifier[] field;	// of Identifier *'s
    Initializer[] value;	// parallel array of Initializer *'s

    VarDeclaration[] vars;		// parallel array of VarDeclaration *'s
    AggregateDeclaration ad;	// which aggregate this is for

    this(Loc loc)
	{
		super(loc);
		ad = null;
	}
	
    override Initializer syntaxCopy()
	{
		auto ai = new StructInitializer(loc);

		assert(field.length == value.length);
		ai.field.reserve(field.length);
		ai.value.reserve(value.length);
		for (int i = 0; i < field.length; i++)
		{    
			ai.field[i] = field[i];

			auto init = value[i];
			init = init.syntaxCopy();
			ai.value[i] = init;
		}

		return ai;
	}
	
    void addInit(Identifier field, Initializer value)
	{
		//printf("StructInitializer.addInit(field = %p, value = %p)\n", field, value);
		this.field ~= (field);
		this.value ~= (value);
	}
	
	
	/***************************************
	 * This works by transforming a struct initializer into
	 * a struct literal. In the future, the two should be the
	 * same thing.
	 */
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}


    override StructInitializer isStructInitializer() { return this; }
}

class VoidInitializer : Initializer
{
    Type type = null;		// type that this will initialize to

    this(Loc loc)
	{
		super(loc);
	}
	
    override Initializer syntaxCopy()
	{
		return new VoidInitializer(loc);
	}
	
	
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("void");
	}


    override VoidInitializer isVoidInitializer() { return this; }
}
