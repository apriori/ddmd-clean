module dmd.expressions.DsymbolExp;

import dmd.Global;
import dmd.Expression;
import dmd.dsymbols.EnumMember;
import dmd.VarDeclaration;
import dmd.declarations.FuncDeclaration;
import dmd.declarations.FuncLiteralDeclaration;
import dmd.dsymbols.OverloadSet;
import dmd.Declaration;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.dsymbols.Import;
import dmd.Package;
import dmd.Type;
import dmd.expressions.DotVarExp;
import dmd.expressions.ThisExp;
import dmd.expressions.VarExp;
import dmd.expressions.FuncExp;
import dmd.expressions.OverExp;
import dmd.expressions.DotTypeExp;
import dmd.expressions.ScopeExp;
import dmd.Module;
import dmd.expressions.TypeExp;
import dmd.declarations.TupleDeclaration;
import dmd.expressions.TupleExp;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.scopeDsymbols.TemplateDeclaration;
import dmd.expressions.TemplateExp;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Dsymbol;
import dmd.Token;
import dmd.expressions.ErrorExp;

import std.array;
import dmd.DDMDExtensions;

class DsymbolExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Dsymbol s;
	bool hasOverloads;

	this(Loc loc, Dsymbol s, bool hasOverloads = false)
	{
		super(loc, TOKdsymbol, DsymbolExp.sizeof);
		this.s = s;
		this.hasOverloads = hasOverloads;
	}


	override string toChars()
	{
		assert(false);
	}


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}


}

