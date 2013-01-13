module yajl.c.parse;

import yajl.c.common;

extern (C):

struct yajl_handle_t {};
alias yajl_handle_t* yajl_handle;

enum yajl_status
{
	yajl_status_ok = 0,
	yajl_status_client_canceled = 1,
	yajl_status_error = 2
}

enum yajl_option
{
	yajl_allow_comments = 1,
	yajl_dont_validate_strings = 2,
	yajl_allow_trailing_garbage = 4,
	yajl_allow_multiple_values = 8,
	yajl_allow_partial_values = 16
}

struct yajl_callbacks
{
	int function (void*) yajl_null;
	int function (void*, int) yajl_boolean;
	int function (void*, long) yajl_integer;
	int function (void*, double) yajl_double;
	int function (void*, const(char)*, size_t) yajl_number;
	int function (void*, const(ubyte)*, size_t) yajl_string;
	int function (void*) yajl_start_map;
	int function (void*, const(ubyte)*, size_t) yajl_map_key;
	int function (void*) yajl_end_map;
	int function (void*) yajl_start_array;
	int function (void*) yajl_end_array;
}

const(char)* yajl_status_to_string (yajl_status code);
yajl_handle yajl_alloc (const(yajl_callbacks)* callbacks, yajl_alloc_funcs* afs, void* ctx);
int yajl_config (yajl_handle h, yajl_option opt, ...);
void yajl_free (yajl_handle handle);
yajl_status yajl_parse (yajl_handle hand, const(ubyte)* jsonText, size_t jsonTextLength);
yajl_status yajl_complete_parse (yajl_handle hand);
ubyte* yajl_get_error (yajl_handle hand, int verbose, const(ubyte)* jsonText, size_t jsonTextLength);
size_t yajl_get_bytes_consumed (yajl_handle hand);
void yajl_free_error (yajl_handle hand, ubyte* str);
