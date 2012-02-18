module dmd.types.TypeBasic;

import dmd.Global;
import dmd.Type;
import dmd.Token;
import dmd.Scope;
import dmd.Expression;
import dmd.Identifier;
import dmd.HdrGenState;
import std.array;


class TypeBasic : Type
{
    string dstring_;
    uint flags;

    this(TY ty)
	{
		super(ty);

		enum TFLAGSintegral	= 1;
		enum TFLAGSfloating = 2;
		enum TFLAGSunsigned = 4;
		enum TFLAGSreal = 8;
		enum TFLAGSimaginary = 0x10;
		enum TFLAGScomplex = 0x20;

		string d;

		uint flags = 0;
		switch (ty)
		{
		case Tvoid:	d = Token.toChars(TOKvoid);
				break;

		case Tint8:	d = Token.toChars(TOKint8);
				flags |= TFLAGSintegral;
				break;

		case Tuns8:	d = Token.toChars(TOKuns8);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Tint16:	d = Token.toChars(TOKint16);
				flags |= TFLAGSintegral;
				break;

		case Tuns16:	d = Token.toChars(TOKuns16);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Tint32:	d = Token.toChars(TOKint32);
				flags |= TFLAGSintegral;
				break;

		case Tuns32:	d = Token.toChars(TOKuns32);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Tfloat32:	d = Token.toChars(TOKfloat32);
				flags |= TFLAGSfloating | TFLAGSreal;
				break;

		case Tint64:	d = Token.toChars(TOKint64);
				flags |= TFLAGSintegral;
				break;

		case Tuns64:	d = Token.toChars(TOKuns64);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Tfloat64:	d = Token.toChars(TOKfloat64);
				flags |= TFLAGSfloating | TFLAGSreal;
				break;

		case Tfloat80:	d = Token.toChars(TOKfloat80);
				flags |= TFLAGSfloating | TFLAGSreal;
				break;

		case Timaginary32: d = Token.toChars(TOKimaginary32);
				flags |= TFLAGSfloating | TFLAGSimaginary;
				break;

		case Timaginary64: d = Token.toChars(TOKimaginary64);
				flags |= TFLAGSfloating | TFLAGSimaginary;
				break;

		case Timaginary80: d = Token.toChars(TOKimaginary80);
				flags |= TFLAGSfloating | TFLAGSimaginary;
				break;

		case Tcomplex32: d = Token.toChars(TOKcomplex32);
				flags |= TFLAGSfloating | TFLAGScomplex;
				break;

		case Tcomplex64: d = Token.toChars(TOKcomplex64);
				flags |= TFLAGSfloating | TFLAGScomplex;
				break;

		case Tcomplex80: d = Token.toChars(TOKcomplex80);
				flags |= TFLAGSfloating | TFLAGScomplex;
				break;

		case Tbool:	d = "bool";
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Tascii:	d = Token.toChars(TOKchar);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Twchar:	d = Token.toChars(TOKwchar);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Tdchar:	d = Token.toChars(TOKdchar);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;
		default:
		}

		this.dstring_ = d;
		this.flags = flags;
		merge();
	}

    override Type syntaxCopy()
	{
		// No semantic analysis done on basic types, no need to copy
		return this;
	}
	
    override ulong size(Loc loc)
	{
		uint size;

		//printf("TypeBasic.size()\n");
		switch (ty)
		{
			case Tint8:
			case Tuns8:	size = 1;	break;
			case Tint16:
			case Tuns16:	size = 2;	break;
			case Tint32:
			case Tuns32:
			case Tfloat32:
			case Timaginary32:
					size = 4;	break;
			case Tint64:
			case Tuns64:
			case Tfloat64:
			case Timaginary64:
					size = 8;	break;
			case Tfloat80:
			case Timaginary80:
					size = REALSIZE;	break;
			case Tcomplex32:
					size = 8;		break;
			case Tcomplex64:
					size = 16;		break;
			case Tcomplex80:
					size = REALSIZE * 2;	break;

			case Tvoid:
				//size = Type.size();	// error message
				size = 1;
				break;

			case Tbool:	size = 1;		break;
			case Tascii:	size = 1;		break;
			case Twchar:	size = 2;		break;
			case Tdchar:	size = 4;		break;

			default:
				assert(0);
		}

		//printf("TypeBasic.size() = %d\n", size);
		return size;
	}
	
    override uint alignsize()
	{
		uint sz;

		switch (ty)
		{
		case Tfloat80:
		case Timaginary80:
		case Tcomplex80:
			sz = REALALIGNSIZE;
			break;

version (POSIX) { ///TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
		case Tint64:
		case Tuns64:
		case Tfloat64:
		case Timaginary64:
		case Tcomplex32:
		case Tcomplex64:
			sz = 4;
			break;
}

		default:
			sz = cast(uint)size(Loc(0));	///
			break;
		}

		return sz;
	}
	
	
	
    override string toChars()
	{
		return Type.toChars();
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		//printf("TypeBasic.toCBuffer2(mod = %d, this.mod = %d)\n", mod, this.mod);
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		buf.put(dstring_);
	}
	
    override bool isintegral()
	{
		//printf("TypeBasic.isintegral('%s') x%x\n", toChars(), flags);
		return (flags & TFLAGSintegral) != 0;
	}
	
    bool isbit()
	{
		assert(false);
	}
	
    override bool isfloating()
	{
		return (flags & TFLAGSfloating) != 0;
	}
	
    override bool isreal()
	{
		return (flags & TFLAGSreal) != 0;
	}
	
    override bool isimaginary()
	{
		return (flags & TFLAGSimaginary) != 0;
	}
	
    override bool iscomplex()
	{
		return (flags & TFLAGScomplex) != 0;
	}

    override bool isscalar()
	{
		return (flags & (TFLAGSintegral | TFLAGSfloating)) != 0;
	}
	
    override bool isunsigned()
	{
		return (flags & TFLAGSunsigned) != 0;
	}
	
	
	
	
    override bool builtinTypeInfo()
	{
		return mod ? false : true;
	}
	
    // For eliminating dynamic_cast
    override TypeBasic isTypeBasic()
	{
		return this;
	}
}
