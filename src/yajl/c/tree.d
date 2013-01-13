module yajl.c.tree;

extern (C):

alias yajl_val_s* yajl_val;

enum yajl_type
{
	yajl_t_string = 1,
	yajl_t_number = 2,
	yajl_t_object = 3,
	yajl_t_array = 4,
	yajl_t_true = 5,
	yajl_t_false = 6,
	yajl_t_null = 7,
	yajl_t_any = 8
}

struct yajl_val_s
{
	yajl_type type;
	union
	{
		char* string;

		struct Num
		{
			long i;
			double d;
			char* r;
			uint flags;
		}
        Num number;

		struct Obj
		{
			const(char*)* keys;
			yajl_val* values;
			size_t len;
		}
        Obj object;

		struct Arr
		{
			yajl_val* values;
			size_t len;
		}
        Arr array;
	}
}

yajl_val yajl_tree_parse (const(char)* input, char* error_buffer, size_t error_buffer_size);
void yajl_tree_free (yajl_val v);
yajl_val yajl_tree_get (yajl_val parent, const(char*)* path, yajl_type type);
