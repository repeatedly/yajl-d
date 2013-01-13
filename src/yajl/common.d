// Written in the D programming language.

module yajl.common;

import yajl.c.common;

import core.memory : GC;

/// Exception for yajl-d
class YajlException : Exception
{
    this(string msg, string filename = __FILE__, size_t line = __LINE__)
    {
        super(msg, filename, line);
    }
}

package:

extern(C)
{
    void* yajlMalloc(void *ctx, size_t sz)
    {
        return GC.malloc(sz);
    }

    void* yajlRealloc(void *ctx, void * previous, size_t sz)
    {
        return GC.realloc(previous, sz);
    }

    void yajlFree(void *ctx, void * ptr)
    {
        GC.free(ptr);
    }

    yajl_alloc_funcs yajlAllocFuncs = yajl_alloc_funcs(&yajlMalloc, &yajlRealloc, &yajlFree);
}

template getFieldName(Type, size_t i)
{
    import std.conv : text;

    static assert((is(Type == class) || is(Type == struct)), "Type must be class or struct: type = " ~ Type.stringof);
    static assert(i < Type.tupleof.length, text(Type.stringof, " has ", Type.tupleof.length, " attributes: given index = ", i));

    // 3 means () + .
    enum getFieldName = Type.tupleof[i].stringof[3 + Type.stringof.length..$];
}

template isNullable(T)
{
    import std.typecons : Nullable;

    static if (is(Unqual!T U: Nullable!U))
    {
        enum isNullable = true;
    }
    else
    {
        enum isNullable = false;
    }
}
