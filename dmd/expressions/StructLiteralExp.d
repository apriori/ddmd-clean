module dmd.expressions.StructLiteralExp;

import dmd.Global;
import std.format;

import dmd.Expression;
import dmd.types.TypeStruct;
import dmd.types.TypeSArray;
import dmd.expressions.ErrorExp;
import dmd.Dsymbol;
import dmd.VarDeclaration;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.declarations.FuncDeclaration;
import dmd.varDeclarations.ThisDeclaration;
import dmd.InterState;
import dmd.Type;
import dmd.Scope;
import dmd.Initializer;
import dmd.HdrGenState;
import dmd.expressions.ArrayLiteralExp;
import dmd.Token;


import std.array;
import dmd.DDMDExtensions;

class StructLiteralExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	StructDeclaration sd;		// which aggregate this is for
	Expression[] elements;	// parallels sd.fields[] with
				// NULL entries for fields to skip

    //Symbol* sym;		// back end symbol to initialize with literal
    size_t soffset;		// offset from start of s
    int fillHoles;		// fill alignment 'holes' with zero

	this(Loc loc, StructDeclaration sd, Expression[] elements)
	{
		super(loc, TOKstructliteral, StructLiteralExp.sizeof);
		this.sd = sd;
		this.elements = elements;
		//this.sym = null; //BACKEND stuff
		this.soffset = 0;
		this.fillHoles = 1;
	}

	override Expression syntaxCopy()
	{
		return new StructLiteralExp(loc, sd, arraySyntaxCopy(elements));
	}


	/**************************************
	 * Gets expression at offset of type.
	 * Returns null if not found.
	 */




	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(sd.toChars());
		buf.put('(');
		argsToCBuffer(buf, elements, hgs);
		buf.put(')');
	}

	override void toMangleBuffer(ref Appender!(char[]) buf)
	{
		size_t dim = elements ? elements.length : 0;
		formattedWrite(buf,"S%u", dim);
		for (size_t i = 0; i < dim; i++)
	    {
			auto e = elements[i];
			if (e)
				e.toMangleBuffer(buf);
			else
				buf.put('v');	// 'v' for void
	    }
	}









}

