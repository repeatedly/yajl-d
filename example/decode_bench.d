import yajl;
import yajl.decoder;

import std.json;
import std.datetime;
import std.stdio;
import std.typecons;

static struct Handa
{
    static struct AAA
    {
        bool ok;
    }

    ulong id;
    string name;
    double height;
    Nullable!AAA aaa;
}

void main()
{
    immutable Num = 10000;

    {
        auto sw = StopWatch(AutoStart.yes);
        foreach (i; 0..Num) {
            parseJSON(`{"id":1000,"name":"shinobu","height":169.5}`);
        }
        sw.stop();
        writefln("json:        %s QPS", Num / sw.peek().to!("seconds", real));
    }
    {
        auto sw = StopWatch(AutoStart.yes);
        foreach (i; 0..Num) {
            decode(`{"id":1000,"name":"shinobu","height":169.5}`);
        }
        sw.stop();
        writefln("yajl(one):   %s QPS", Num / sw.peek().to!("seconds", real));
    }
    {
        auto sw = StopWatch(AutoStart.yes);
        foreach (i; 0..Num) {
            decode!(Handa)(`{"id":1000,"name":"shinobu","height":169.5}`);
        }
        sw.stop();
        writefln("yajl(conv):  %s QPS", Num / sw.peek().to!("seconds", real));
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
        writefln("yajl(multi): %s QPS", Num / sw.peek().to!("seconds", real));
    }
}
