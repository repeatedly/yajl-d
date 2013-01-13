// Written in the D programming language.

module yajl.common;

import yajl.c.common;

import core.memory : GC;


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
