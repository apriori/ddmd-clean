module dmd.initializers.ArrayInitializer;

import dmd.Global;
import dmd.Type;
import dmd.types.TypeAArray;
import dmd.types.TypeNext;
import dmd.Initializer;
import dmd.types.TypeSArray;
import dmd.expressions.IntegerExp;
import dmd.Expression;
import dmd.expressions.ArrayLiteralExp;
import dmd.expressions.AssocArrayLiteralExp;
import dmd.Scope;
import dmd.expressions.ErrorExp;
import dmd.HdrGenState;
import std.array;


import dmd.DDMDExtensions;

class ArrayInitializer : Initializer
{
	mixin insertMemberExtension!(typeof(this));

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
