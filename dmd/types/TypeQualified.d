module dmd.types.TypeQualified;

import dmd.Global;
import dmd.Type;
import dmd.dsymbols.Import;
import dmd.expressions.DsymbolExp;
import dmd.expressions.TypeExp;
import dmd.expressions.DotIdExp;
import dmd.VarDeclaration;
import dmd.dsymbols.EnumMember;
import dmd.declarations.TupleDeclaration;
import dmd.expressions.VarExp;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.Identifier;
import dmd.HdrGenState;
import std.array;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.declarations.FuncDeclaration;

import dmd.DDMDExtensions;

class TypeQualified : Type
{
	mixin insertMemberExtension!(typeof(this));

    Loc loc;
    Identifier[] idents;	// array of Identifier's representing ident.ident.ident etc.

    this(TY ty, Loc loc)
	{
		super(ty);
		this.loc = loc;
		
	}

    void addIdent(Identifier ident)
	{
		assert(ident !is null);
		idents ~= ident;
	}

    void toCBuffer2Helper(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		int i;

		for (i = 0; i < idents.length; i++)
		{
			Identifier id = idents[i];
			buf.put('.');

			if (id.dyncast() == DYNCAST_DSYMBOL)
			{
				TemplateInstance ti = cast(TemplateInstance)id;
				ti.toCBuffer(buf, hgs);
			} else {
				buf.put(id.toChars());
			}
		}
	}
	
	

}
