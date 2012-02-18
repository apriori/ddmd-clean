module dmd.ModuleDeclaration;
// zdclean I think

import dmd.Identifier;

import std.array; // appender!(char[])


class ModuleDeclaration
{
    Identifier id;
    Identifier[] packages;		// array of Identifier's representing package
    bool safe;

    this(Identifier[] packages, Identifier id, bool safe)
	{
		this.packages = packages;
		this.id = id;
		this.safe = safe;
	}

    string toChars()
	{
      auto buf = appender!(char[])();
		if (packages)
		{
			foreach (pid; packages)
			{
            buf.put(pid.toChars());
				buf.put('.');
			}
		}
		buf.put(id.toChars());
		return buf.data.idup;
	}
}
