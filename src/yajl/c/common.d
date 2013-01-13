module yajl.c.common;

import core.stdc.config;

extern (C):

alias void* function(void*, c_ulong) yajl_malloc_func;
alias void function(void*, void*) yajl_free_func;
alias void* function(void*, void*, c_ulong) yajl_realloc_func;

struct yajl_alloc_funcs
{
	yajl_malloc_func malloc;
	yajl_realloc_func realloc;
	yajl_free_func free;
	void* ctx;
}
