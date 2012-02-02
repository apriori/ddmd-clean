module dmd.Parameter;

import dmd.Global;
import dmd.Type;
import dmd.Dsymbol;
import dmd.Identifier;
import dmd.types.TypeArray;
import dmd.types.TypeFunction;
import dmd.types.TypeDelegate;
import dmd.types.TypeTuple;
import dmd.Expression;
import dmd.HdrGenState;
import std.array;
import dmd.attribDeclarations.StorageClassDeclaration;
import dmd.Declaration;

import dmd.DDMDExtensions;

class Parameter 
{
	mixin insertMemberExtension!(typeof(this));

    //enum InOut inout;
    StorageClass storageClass;
    Type type;
    Identifier ident;
    Expression defaultArg;

    this(StorageClass storageClass, Type type, Identifier ident, Expression defaultArg)
	{
		this.type = type;
		this.ident = ident;
		this.storageClass = storageClass;
		this.defaultArg = defaultArg;
	}
	
	Parameter clone()
	{
		return new Parameter(storageClass, type, ident, defaultArg);
	}
	
    Parameter syntaxCopy()
	{
		return new Parameter(storageClass, type ? type.syntaxCopy() : null, ident, defaultArg ? defaultArg.syntaxCopy() : null);
	}
	
    void toDecoBuffer(ref Appender!(char[]) buf)
	{
		if (storageClass & STCscope)
			buf.put('M');
		switch (storageClass & (STCin | STCout | STCref | STClazy))
		{   
			case STCundefined:
			case STCin:
				break;
			case STCout:
				buf.put('J');
				break;
			case STCref:
				buf.put('K');
				break;
			case STClazy:
				buf.put('L');
				break;
        default: break;
		}
		//type.toHeadMutable().toDecoBuffer(buf, 0);
		type.toDecoBuffer(buf, 0);
	}
	
    static Parameter[] arraySyntaxCopy(Parameter[] args)
	{
		typeof(return) a = null;

		if (args)
		{
			a.reserve(args.length);

			for (size_t i = 0; i < a.length; i++)
			{   
				auto arg = args[i];

				arg = arg.syntaxCopy();
				a[i] = arg;
			}
		}
	
		return a;
	}
	
    static string argsTypesToChars(Parameter[] args, int varargs)
	{
		auto buf = appender!(char[])();

	static if (true) {
		HdrGenState hgs;
		argsToCBuffer(buf, hgs, args, varargs);
	} else {
		buf.put('(');
		if (args)
		{	
			auto argbuf = appender!(char[])();
			HdrGenState hgs;

			for (int i = 0; i < args.length; i++)
			{   
				if (i)
					buf.put(',');
				auto arg = cast(Parameter)args.data[i];
				argbuf.clear();
				arg.type.toCBuffer2(&argbuf, hgs, 0);
				buf.write(&argbuf);
			}
			if (varargs)
			{
				if (i && varargs == 1)
					buf.put(',');
				buf.put("...");
			}
		}
		buf.put(')');
	}
		return buf.data.idup;
	}
	
    static void argsToCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs, Parameter[] arguments, int varargs)
	{
		buf.put('(');
		if (arguments)
		{	
			int i;
			auto argbuf = appender!(char[])();

			for (i = 0; i < arguments.length; i++)
			{
				if (i)
					buf.put(", ");
				auto arg = arguments[i];

	            if (arg.storageClass & STCauto)
		            buf.put("auto ");

				if (arg.storageClass & STCout)
					buf.put("out ");
				else if (arg.storageClass & STCref)
					buf.put((global.params.Dversion == 1) ? "inout " : "ref ");
				else if (arg.storageClass & STCin)
					buf.put("in ");
				else if (arg.storageClass & STClazy)
					buf.put("lazy ");
				else if (arg.storageClass & STCalias)
					buf.put("alias ");

				StorageClass stc = arg.storageClass;
				if (arg.type && arg.type.mod & MODshared)
					stc &= ~STCshared;

				StorageClassDeclaration.stcToCBuffer(buf, stc & (STCconst | STCimmutable | STCshared | STCscope));

				argbuf.clear();
				if (arg.storageClass & STCalias)
				{	
					if (arg.ident)
						argbuf.put(arg.ident.toChars());
				}
				else
					arg.type.toCBuffer(argbuf, arg.ident, hgs);
				if (arg.defaultArg)
				{
					argbuf.put(" = ");
					arg.defaultArg.toCBuffer(argbuf, hgs);
				}
				buf.put(argbuf.data);
			}
			if (varargs)
			{
				if (i && varargs == 1)
					buf.put(',');
				buf.put("...");
			}
		}
		buf.put(')');
	}
    
    static int isTPL(Parameter[] arguments)
	{
		assert(false);
	}
	
    static void argsToDecoBuffer(ref Appender!(char[]) buf, Parameter[] arguments)
    {
        assert(false);
    }

    void getNth()( Parameter[] arguments, size_t i)
    {
        assert(false);
    }

    static int isTPL(Parameter[] arguments)
	{
		assert(false);
	}

	/***************************************
	 * Determine number of arguments, folding in tuples.
	 */	
	
	/***************************************
	 * Get nth Parameter, folding in tuples.
	 * Returns:
	 *	Parameter	nth Parameter
	 *	null		not found, *pn gets incremented by the number
	 *			of Parameters
	 */
}
