package net.rezmason.utils.workers;

class TestWorker extends BasicWorker<Int, String> {

    public function new():Void {
        super();
    }

    override function process(data) {
        if (data == -1) throw 'BLARG';
        return Std.string(data);
    }
}
