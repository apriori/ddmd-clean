//module main; //??

import dmd.Global;
import dmd.Module;
import dmd.Lexer;
import dmd.Type;
import dmd.Id;
import dmd.Identifier;
import dmd.Token;

import std.string; 
import std.exception;
import std.file;
import std.path; 
import std.stdio;
import std.getopt;
import std.process;
import std.array; // split, appender

int main(string[] args)
{
    // global defaults: see dmd.Global.static this(){}
    // D has no need for setting global defaults in the main program

    // Deal with options.
    /+ CODE DEALING WITH OPTIONS GOES HERE +/

    // The following are now initialized in their appropriate modules
    /+
    Type.init();
    Id.initialize();
    initPrecedence();
    +/
    // Gone. I don't know what it did
    //global.initClasssym();

    // Load, read, and parse all modules
    // Module m;
    // ETC.
    
    // Semantic, Optimize, and all the Rest, here on Gilligan's Isle!
    
    if (global.errors)
        fatal();
    return 0;
}
