module dmd.types.TypeStruct;

import dmd.Global;
import std.format;

import dmd.Type;
import dmd.types.TypeInstance;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.Declaration;
import dmd.expressions.DotVarExp;
import std.array;
import dmd.scopeDsymbols.TemplateMixin;
import dmd.expressions.DotTemplateExp;
import dmd.expressions.DsymbolExp;
import dmd.expressions.TypeExp;
import dmd.dsymbols.EnumMember;
import dmd.expressions.DotIdExp;
import dmd.expressions.ScopeExp;
import dmd.expressions.TupleExp;
import dmd.scopeDsymbols.TemplateDeclaration;
import dmd.dsymbols.OverloadSet;
import dmd.dsymbols.Import;
import dmd.expressions.DotExp;
import dmd.expressions.ErrorExp;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.Identifier;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.declarations.FuncDeclaration;
import dmd.expressions.VarExp;
import dmd.expressions.CommaExp;
import dmd.expressions.ThisExp;
import dmd.expressions.StructLiteralExp;
import dmd.declarations.SymbolDeclaration;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.varDeclarations.TypeInfoStructDeclaration;
import dmd.Token;
import dmd.VarDeclaration;


import std.string : toStringz;

import dmd.DDMDExtensions;

class TypeStruct : Type
{
	mixin insertMemberExtension!(typeof(this));

    StructDeclaration sym;

    this(StructDeclaration sym)
	{
		super(Tstruct);
		this.sym = sym;
	}
    override ulong size(Loc loc)
	{
		return sym.size(loc);
	}

    override uint alignsize()
	{
		uint sz;

		sym.size(Loc(0));		// give error for forward references
		sz = sym.alignsize;
		if (sz > sym.structalign)
			sz = sym.structalign;
		return sz;
	}

    override string toChars()
	{
		//printf("sym.parent: %s, deco = %s\n", sym.parent.toChars(), deco);
		if (mod)
			return Type.toChars();
		TemplateInstance ti = sym.parent.isTemplateInstance();
		if (ti && ti.toAlias() == sym)
		{
			return ti.toChars();
		}
		return sym.toChars();
	}

    override Type syntaxCopy()
	{
		assert(false);
	}



    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		string name = sym.mangle();
		//printf("TypeStruct.toDecoBuffer('%s') = '%s'\n", toChars(), name);
		Type.toDecoBuffer(buf, flag);
		formattedWrite(buf,"%s", name);
	}

    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{
			toCBuffer3(buf, hgs, mod);
			return;
		}
		TemplateInstance ti = sym.parent.isTemplateInstance();
		if (ti && ti.toAlias() == sym)
			buf.put(ti.toChars());
		else
			buf.put(sym.toChars());
	}




    /***************************************
     * Use when we prefer the default initializer to be a literal,
     * rather than a global immutable variable.
     */


    override bool isAssignable()
	{
		/* If any of the fields are const or invariant,
		 * then one cannot assign this struct.
		 */
		for (size_t i = 0; i < sym.fields.length; i++)
		{
			VarDeclaration v = cast(VarDeclaration)sym.fields[i];
			if (v.isConst() || v.isImmutable())
				return false;
		}
		return true;
	}

    override bool checkBoolean()
	{
		return false;
	}



    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoStructDeclaration(this);
	}




    override Type toHeadMutable()
	{
		assert(false);
	}


}
