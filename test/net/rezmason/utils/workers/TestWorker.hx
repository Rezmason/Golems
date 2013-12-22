package net.rezmason.utils.workers;

class TestWorker extends BasicWorker<Int, String> {

    public function new():Void {
        super();
    }

    override function receive(data:Int):Void {
        if (data == -1) sendError('BLARG');
        else send(Std.string(data));
    }
}
