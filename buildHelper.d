// Written in The D Programming Language
/// Script to build DDMD
import std.file;
import std.getopt;
import std.path;
import std.process;
import std.stdio;
import std.string: replace, format;
import std.zip;

int main(string args)
{
    int exitStatus = 0;
    endOfOptions = "";
    bool help;
    getopt(
		  args,
		  std.getopt.config.caseSensitive,
		  "help|h|H|?", &help
    );
    if ( help ) 
    {
        stdout.write( helpMsg );
        return 1; // FAIL!
    }

    // compile
    auto derelictOpts = derelictImportOpts ~ derelictLinkerOpts;
    auto cmd = "dmd "~ derelictOpts ~"zddmd.d -ofzddmd";

    return exitStatus;
}

enum derelictImportOpts = "-I/Users/zach/SourceCode/Derelict2/import ";
enum derelictLinkerOpts = "-L-L/Users/zach/SourceCode/Derelict2/lib -L-lDerelictSDL -L-lDerelictUtil -L-lDerelictSDLttf -L-lDerelictSDLimage ";

// actually I don't think the enum will compile with the semicolon there
version(Windows)
{
    enum 
    {
        osSubDir   = "windows";
        scriptName = "build.bat",
        configFile = "sc.ini",
        execExt    = ".exe",
        dmdLib = "dmd.lib"
    } 
} 
else
{  
    // zd What I really need is to recklessly chuck most of this
    version (OSX) 
        enum osSubDir = "osx";
    else version (linux) 
        enum osSubDir = "linux";
    enum 
    {
        scriptName = "./build.sh";
        configFile = "dmd.conf",
        execExt    = "",
        dmdLib = "libdmd.a"
    }
}

void doCopy(string from, string to)
{
	from = normFilePath(from);
	to   = normFilePath(to);
	
	writefln(`copy "%s" "%s"`, from, to);
	file.copy(from, to);
}

int doSystem(string cmd)
{
	writeln(cmd);
	stdout.flush();
	return process.system(cmd);
}

enum helpMsg = 
`This script is supposed to compile zddmd. Brace yourself!
No, really, I suck. Just roll with it. Maybe I'll add a few options
when the program gets liftoff.
`; // wonder if I can do: (`yada` `yada` `yada`) string concats
