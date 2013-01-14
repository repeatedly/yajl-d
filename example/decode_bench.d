import yajl.decoder;
import yajl.yajl;

import std.json;
import std.datetime;
import std.stdio;

void main()
{
    immutable Num = 10000;

    {
        auto sw = StopWatch(AutoStart.yes);
        foreach (i; 0..Num) {
            parseJSON(`{"id":1000,"name":"shinobu","height":169.5}`);
        }
        sw.stop();
        writefln("json:         %s QPS", Num / sw.peek().to!("seconds", real));
    }
    {
        auto sw = StopWatch(AutoStart.yes);
        foreach (i; 0..Num) {
            decode(`{"id":1000,"name":"shinobu","height":169.5}`);
        }
        sw.stop();
        writefln("yajl(one):    %s QPS", Num / sw.peek().to!("seconds", real));
    }
    {
        auto sw = StopWatch(AutoStart.yes);
        Decoder.Option opt;
        opt.allowMultipleValues = true;
        Decoder decoder = Decoder(opt);
        foreach (i; 0..Num) {
            decoder.decode(`{"id":1000,"name":"shinobu","height":169.5}`);
            decoder.decodedValue;
        }
        sw.stop();
        writefln("yajl(stream): %s QPS", Num / sw.peek().to!("seconds", real));
    }
}
