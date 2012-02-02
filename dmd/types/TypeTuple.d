module dmd.types.TypeTuple;

import dmd.Global;
import std.format;

import dmd.Type;
import dmd.varDeclarations.TypeInfoTupleDeclaration;
import dmd.varDeclarations.TypeInfoDeclaration;
import dmd.Expression;
import dmd.Identifier;
import dmd.HdrGenState;
import std.array;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.Parameter;
import dmd.expressions.ErrorExp;
import dmd.expressions.IntegerExp;

import dmd.DDMDExtensions;

class TypeTuple : Type
{
	mixin insertMemberExtension!(typeof(this));

	Parameter[] arguments;	// types making up the tuple

	this(Parameter[] arguments)
	{
		super(Ttuple);
		//printf("TypeTuple(this = %p)\n", this);
		this.arguments = arguments;
		//printf("TypeTuple() %p, %s\n", this, toChars());
		debug {
			if (arguments)
			{
				foreach (arg; arguments)
				{
					assert(arg && arg.type);
				}
			}
		}
	}

	/****************
	 * Form TypeTuple from the types of the expressions.
	 * Assume exps[] is already tuple expanded.
	 */
	this(Expression[] exps)
	{
		super(Ttuple);
		Parameter[] arguments;
		if (exps)
		{
			arguments.reserve(exps.length);
			for (size_t i = 0; i < exps.length; i++)
			{   auto e = exps[i];
				if (e.type.ty == Ttuple)
					e.error("cannot form tuple of tuples");
				auto arg = new Parameter(STCundefined, e.type, null, null);
				arguments[i] = arg;
			}
		}
		this.arguments = arguments;
        //printf("TypeTuple() %p, %s\n", this, toChars());
	}

	override Type syntaxCopy()
	{
		auto args = Parameter.arraySyntaxCopy(arguments);
		auto t = new TypeTuple(args);
		t.mod = mod;
		return t;
	}


	override bool equals(Object o)
	{
		Type t;

		t = cast(Type)o;
		//printf("TypeTuple::equals(%s, %s)\n", toChars(), t-cast>toChars());
		if (this == t)
		{
			return 1;
		}
		if (t.ty == Ttuple)
		{	auto tt = cast(TypeTuple)t;

			if (arguments.length == tt.arguments.length)
			{
				for (size_t i = 0; i < tt.arguments.length; i++)
				{   auto arg1 = arguments[i];
					auto arg2 = tt.arguments[i];

					if (!arg1.type.equals(arg2.type))
						return 0;
				}
				return 1;
			}
		}
		return 0;
	}

	override Type reliesOnTident()
	{
		if (arguments)
		{
			foreach (arg; arguments)
			{
				auto t = arg.type.reliesOnTident();
				if (t)
					return t;
			}
		}
		return null;
	}

	override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		Parameter.argsToCBuffer(buf, hgs, arguments, 0);
	}

	override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		//printf("TypeTuple::toDecoBuffer() this = %p, %s\n", this, toChars());
		Type.toDecoBuffer(buf, flag);
		auto buf2 = appender!(char[])();
		Parameter.argsToDecoBuffer(buf2, arguments);
		//buf.printf("%d%.*s", len, len, cast(char *)buf2.extractData());
		formattedWrite(buf,"%s", buf2.data);
	}


	override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoTupleDeclaration(this);
	}
}
