package net.rezmason.utils.workers;

class QuickBoss<TInput, TOutput> extends BasicBoss<TInput, TOutput> {

    public var onReceive:TOutput->Void;
    public var onError:Dynamic->Void;

    public function new(core, onReceive:TOutput->Void = null, onError:Dynamic->Void = null):Void {
        super(core);
        this.onReceive = onReceive;
        this.onError = onError;
    }

    override function receive(data:TOutput):Void if (onReceive != null) onReceive(data);
    override function onErrorIncoming(error:Dynamic):Void if (onError != null) onError(error);
}
