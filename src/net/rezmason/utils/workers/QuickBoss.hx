package net.rezmason.utils.workers;

class QuickBoss<T, U> extends BasicBoss<T, U> {

    var onReceive:U->Void;
    var onError:Dynamic->Void;

    public function new(core, onReceive:U->Void, onError:Dynamic->Void = null):Void {
        super(core);
        this.onReceive = onReceive;
        this.onError = onError;
    }

    override function receive(data:U):Void if (onReceive != null) onReceive(data);
    override function onErrorIncoming(error:Dynamic):Void if (onError != null) onError(error);
}
