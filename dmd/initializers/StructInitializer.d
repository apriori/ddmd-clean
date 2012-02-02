module dmd.initializers.StructInitializer;

import dmd.Global;
import dmd.Initializer;
import dmd.Token;
import dmd.types.TypeSArray;
import dmd.declarations.FuncLiteralDeclaration;
import dmd.types.TypeFunction;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.expressions.StructLiteralExp;
import dmd.Type;
import dmd.Scope;
import dmd.Identifier;
import dmd.statements.CompoundStatement;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.HdrGenState;
import std.array;
import dmd.Expression;
import dmd.types.TypeStruct;
import dmd.VarDeclaration;
import dmd.Dsymbol;
import dmd.initializers.ExpInitializer;
import dmd.expressions.FuncExp;


import dmd.DDMDExtensions;

class StructInitializer : Initializer
{
	mixin insertMemberExtension!(typeof(this));

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
