module yajl.exception;

class YajlException : Exception
{
    this(string msg, string filename = __FILE__, size_t line = __LINE__)
    {
        super(msg, filename, line);
    }
}
