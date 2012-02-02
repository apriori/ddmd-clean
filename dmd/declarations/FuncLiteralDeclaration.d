module dmd.declarations.FuncLiteralDeclaration;

import dmd.Global;
import dmd.declarations.FuncDeclaration;
import dmd.Token;
import dmd.Identifier;
import dmd.Type;
import dmd.statements.ForeachStatement;
import dmd.HdrGenState;
import std.array;
import dmd.Dsymbol;
import dmd.Lexer;

import dmd.DDMDExtensions;

class FuncLiteralDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    TOK tok;			// TOKfunction or TOKdelegate

    this(Loc loc, Loc endloc, Type type, TOK tok, ForeachStatement fes)
	{
		super(loc, endloc, null, STCundefined, type);
		
		string id;

		if (fes)
			id = "__foreachbody";
		else if (tok == TOKdelegate)
			id = "__dgliteral";
		else
			id = "__funcliteral";

		this.ident = Identifier.uniqueId(id);
		this.tok = tok;
		this.fes = fes;

		//printf("FuncLiteralDeclaration() id = '%s', type = '%s'\n", this->ident->toChars(), type->toChars());
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
    	buf.put(kind());
        buf.put(' ');
        type.toCBuffer(buf, null, hgs);
        bodyToCBuffer(buf, hgs);
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		FuncLiteralDeclaration f;

		//printf("FuncLiteralDeclaration.syntaxCopy('%s')\n", toChars());
		if (s)
			f = cast(FuncLiteralDeclaration)s;
		else
		{	
			f = new FuncLiteralDeclaration(loc, endloc, type.syntaxCopy(), tok, fes);
			f.ident = ident;		// keep old identifier
		}
		FuncDeclaration.syntaxCopy(f);
		return f;
	}
	
    override bool isNested()
	{
		//printf("FuncLiteralDeclaration::isNested() '%s'\n", toChars());
		return (tok == TOKdelegate);
	}
	
    override bool isVirtual()
	{
		return false;
	}

    override FuncLiteralDeclaration isFuncLiteralDeclaration() { return this; }

    override string kind()
	{
		return (tok == TOKdelegate) ? "delegate" : "function";
	}
}
