module dmd.declarations.AliasDeclaration;

import dmd.Global;
import dmd.Declaration;
import dmd.declarations.TypedefDeclaration;
import dmd.VarDeclaration;
import dmd.declarations.FuncDeclaration;
import dmd.declarations.FuncAliasDeclaration;
import dmd.Dsymbol;
import dmd.ScopeDsymbol;
import dmd.Identifier;
import dmd.Type;
import dmd.HdrGenState;
import std.array;
import dmd.Scope;
import dmd.Expression;

import dmd.DDMDExtensions;

class AliasDeclaration : Declaration
{
	mixin insertMemberExtension!(typeof(this));

	Dsymbol aliassym;
	Dsymbol overnext;		// next in overload list
	int inSemantic;

	this(Loc loc, Identifier ident, Type type)
	{
		super(ident);

		//printf("AliasDeclaration(id = '%s', type = %p)\n", id.toChars(), type);
		//printf("type = '%s'\n", type.toChars());
		this.loc = loc;
		this.type = type;
		this.aliassym = null;
		version (_DH) {
			this.htype = null;
			this.haliassym = null;
		}

		assert(type);
	}

	this(Loc loc, Identifier id, Dsymbol s)
	{
		super(id);

		//printf("AliasDeclaration(id = '%s', s = %p)\n", id->toChars(), s);
		assert(s !is this);	/// huh?
		this.loc = loc;
		this.type = null;
		this.aliassym = s;
		version (_DH) {
			this.htype = null;
			this.haliassym = null;
		}
		assert(s);
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		//printf("AliasDeclaration::syntaxCopy()\n");
		assert(!s);
		AliasDeclaration sa;
		if (type)
			sa = new AliasDeclaration(loc, ident, type.syntaxCopy());
		else
			sa = new AliasDeclaration(loc, ident, aliassym.syntaxCopy(null));
version (_DH) {
		// Syntax copy for header file
		if (!htype)	    // Don't overwrite original
		{	if (type)	// Make copy for both old and new instances
			{   htype = type.syntaxCopy();
				sa.htype = type.syntaxCopy();
			}
		}
		else			// Make copy of original for new instance
			sa.htype = htype.syntaxCopy();
		if (!haliassym)
		{	if (aliassym)
			{   haliassym = aliassym.syntaxCopy(s);
				sa.haliassym = aliassym.syntaxCopy(s);
			}
		}
		else
			sa.haliassym = haliassym.syntaxCopy(s);
} // version (_DH)
		return sa;
	}


	override bool overloadInsert(Dsymbol s)
	{
		/* Don't know yet what the aliased symbol is, so assume it can
		 * be overloaded and check later for correctness.
		 */

		//printf("AliasDeclaration.overloadInsert('%s')\n", s.toChars());
		if (overnext is null)
		{
static if (true)
{
			if (s is this)
				return true;
}
			overnext = s;
			return true;

		}
		else
		{
			return overnext.overloadInsert(s);
		}
	}

	override string kind()
	{
		return "alias";
	}

	override Type getType()
	{
		return type;
	}

	override Dsymbol toAlias()
	{
		//printf("AliasDeclaration::toAlias('%s', this = %p, aliassym = %p, kind = '%s')\n", toChars(), this, aliassym, aliassym ? aliassym->kind() : "");
		assert(this !is aliassym);
		//static int count; if (++count == 10) *(char*)0=0;
		if (inSemantic)
		{
			error("recursive alias declaration");
			aliassym = new TypedefDeclaration(loc, ident, Type.terror, null);
		}

		Dsymbol s = aliassym ? aliassym.toAlias() : this;
		return s;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("alias ");
///	static if (false) { // && _DH
///		if (hgs.hdrgen)
///		{
///			if (haliassym)
///			{
///				haliassym.toCBuffer(buf, hgs);
///				buf.put(' ');
///				buf.put(ident.toChars());
///			}
///			else
///				htype.toCBuffer(buf, ident, hgs);
///		}
///		else
///	}
		{
		if (aliassym)
		{
			aliassym.toCBuffer(buf, hgs);
			buf.put(' ');
			buf.put(ident.toChars());
		}
		else
			type.toCBuffer(buf, ident, hgs);
		}
		buf.put(';');
		buf.put('\n');
	}

	version (_DH) {
		Type htype;
		Dsymbol haliassym;
	}
	override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}

	override AliasDeclaration isAliasDeclaration() { return this; }
	}
