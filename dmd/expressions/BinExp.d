module dmd.expressions.BinExp;

import dmd.Global;
import dmd.expressions.SliceExp;
import dmd.expressions.IndexExp;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.expressions.ArrayLiteralExp;
import dmd.expressions.AssocArrayLiteralExp;
import dmd.expressions.StringExp;
import dmd.types.TypeSArray;
import dmd.expressions.PtrExp;
import dmd.expressions.SymOffExp;
import dmd.Declaration;
import dmd.expressions.StructLiteralExp;
import dmd.Expression;
import dmd.Cast;
import dmd.expressions.CastExp;
import dmd.VarDeclaration;
import dmd.expressions.DotVarExp;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.HdrGenState;
import dmd.Token;
import dmd.Scope;
import dmd.Type;
import dmd.InterState;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.Identifier;
import dmd.types.TypeClass;
import dmd.types.TypeStruct;
import dmd.Dsymbol;
import dmd.declarations.FuncDeclaration;
import dmd.scopeDsymbols.TemplateDeclaration;
import dmd.expressions.DotIdExp;
import dmd.expressions.ErrorExp;
import dmd.expressions.IntegerExp;
import dmd.expressions.MulExp;
import dmd.Parameter;
import dmd.Statement;
import dmd.statements.ForeachRangeStatement;
import dmd.expressions.ArrayLengthExp;
import dmd.expressions.IdentifierExp;
import dmd.statements.ExpStatement;
import dmd.statements.CompoundStatement;
import dmd.types.TypeFunction;
import dmd.Lexer;
import dmd.statements.ReturnStatement;
import dmd.expressions.VarExp;
import dmd.expressions.CallExp;




import std.exception : assumeUnique;
import std.stdio : writef;
import std.array;

import dmd.DDMDExtensions;

/**************************************
 * Combine types.
 * Output:
 *	*pt	merged type, if *pt is not null
 *	*pe1	rewritten e1
 *	*pe2	rewritten e2
 * Returns:
 *	!=0	success
 *	0	failed
 */

/**************************************
 * Hash table of array op functions already generated or known about.
 */

//int typeMerge(Scope sc, Expression e, Type* pt, Expression* pe1, Expression* pe2) { assert (false,"zd cut"); }

class BinExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

    Expression e1;
    Expression e2;

    this(Loc loc, TOK op, int size, Expression e1, Expression e2)
	{

		super(loc, op, size);
		this.e1 = e1;
		this.e2 = e2;
	}

    override Expression syntaxCopy()
	{
		BinExp e = cast(BinExp)copy();
		e.type = null;
		e.e1 = e.e1.syntaxCopy();
		e.e2 = e.e2.syntaxCopy();

		return e;
	}

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, precedence[op]);
		buf.put(' ');
		buf.put(Token.toChars(op));
		buf.put(' ');
		expToCBuffer(buf, hgs, e2, cast(PREC)(precedence[op] + 1));
	}

}
