import massive.munit.client.PrintClientBase;

class SimpleTestClient extends PrintClientBase
{

    public function new(?includeIgnoredReport:Bool = true)
    {
        super(includeIgnoredReport);
        id = "simple";
    }

    override function init():Void
    {
        super.init();
        originalTrace = haxe.Log.trace;
        haxe.Log.trace = customTrace;
    }

    function customTrace(value, ?info:haxe.PosInfos) addTrace(value, info);
}
