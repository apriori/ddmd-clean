module dmd.scopeDsymbols.ArrayScopeSymbol;

import dmd.Global;
import dmd.ScopeDsymbol;
import dmd.Expression;
import dmd.types.TypeTuple;
import dmd.declarations.TupleDeclaration;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.Token;
import dmd.Identifier;
import dmd.expressions.TupleExp;
import dmd.expressions.StringExp;
import dmd.expressions.TypeExp;
import dmd.Type;
import dmd.expressions.SliceExp;
import dmd.expressions.IndexExp;
import dmd.expressions.IntegerExp;
import dmd.initializers.ExpInitializer;
import dmd.VarDeclaration;
import dmd.expressions.ArrayLiteralExp;

import dmd.DDMDExtensions;

class ArrayScopeSymbol : ScopeDsymbol
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;	// IndexExp or SliceExp
    TypeTuple type;	// for tuple[length]
    TupleDeclaration td;	// for tuples of objects
    Scope sc;

    this(Scope sc, Expression e)
	{
		super();
		assert(e.op == TOKindex || e.op == TOKslice);
		this.exp = e;
		this.sc = sc;
	}
	
    this(Scope sc, TypeTuple t)
	{
		exp = null;
		type = t;
		td = null;
		this.sc = sc;
	}
	
    this(Scope sc, TupleDeclaration s)
	{

		exp = null;
		type = null;
		td = s;
		this.sc = sc;
	}
	

    override ArrayScopeSymbol isArrayScopeSymbol() { return this; }
}
