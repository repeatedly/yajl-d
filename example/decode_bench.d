import yajl.decoder;

import std.json;
import std.datetime;
import std.stdio;

void main()
{
    immutable Num = 10000;

    Decoder.Option opt;
    opt.allowMultipleValues = true;
    {
        auto sw = StopWatch(AutoStart.yes);
        Decoder decoder = Decoder(opt);
        foreach (i; 0..Num) {
            decoder.decode(`{"id":1000,"name":"shinobu","height":169.5}`);
            decoder.decodedValue;
        }
        sw.stop();
        writefln("yajl %s QPS: ", cast(real)Num / sw.peek().msecs * 1000);
    }
    {
        auto sw = StopWatch(AutoStart.yes);
        foreach (i; 0..Num) {
            parseJSON(`{"id":1000,"name":"shinobu","height":169.5}`);
        }
        sw.stop();
        writefln("json %s QPS: ", cast(real)Num / sw.peek().msecs * 1000);
    }
}
