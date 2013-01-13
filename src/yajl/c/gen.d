module yajl.c.gen;

import yajl.c.common;

import core.stdc.config;

extern (C):

struct yajl_gen_t {};
alias yajl_gen_t* yajl_gen;
alias void function (void*, const(char)*, c_ulong) yajl_print_t;

enum yajl_gen_status
{
	yajl_gen_status_ok = 0,
	yajl_gen_keys_must_be_strings = 1,
	yajl_max_depth_exceeded = 2,
	yajl_gen_in_error_state = 3,
	yajl_gen_generation_complete = 4,
	yajl_gen_invalid_number = 5,
	yajl_gen_no_buf = 6,
	yajl_gen_invalid_string = 7
}

enum yajl_gen_option
{
	yajl_gen_beautify = 1,
	yajl_gen_indent_string = 2,
	yajl_gen_print_callback = 4,
	yajl_gen_validate_utf8 = 8,
	yajl_gen_escape_solidus = 16
}

int yajl_gen_config (yajl_gen g, yajl_gen_option opt, ...);
yajl_gen yajl_gen_alloc (const(yajl_alloc_funcs)* allocFuncs);
void yajl_gen_free (yajl_gen handle);
yajl_gen_status yajl_gen_integer (yajl_gen hand, long number);
yajl_gen_status yajl_gen_double (yajl_gen hand, double number);
yajl_gen_status yajl_gen_number (yajl_gen hand, const(char)* num, size_t len);
yajl_gen_status yajl_gen_string (yajl_gen hand, const(ubyte)* str, size_t len);
yajl_gen_status yajl_gen_null (yajl_gen hand);
yajl_gen_status yajl_gen_bool (yajl_gen hand, int boolean);
yajl_gen_status yajl_gen_map_open (yajl_gen hand);
yajl_gen_status yajl_gen_map_close (yajl_gen hand);
yajl_gen_status yajl_gen_array_open (yajl_gen hand);
yajl_gen_status yajl_gen_array_close (yajl_gen hand);
yajl_gen_status yajl_gen_get_buf (yajl_gen hand, const(ubyte*)* buf, size_t* len);
void yajl_gen_clear (yajl_gen hand);
