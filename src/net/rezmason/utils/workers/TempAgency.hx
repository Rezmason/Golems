package net.rezmason.utils.workers;

import haxe.io.Bytes;

import haxe.Timer;

class TempAgency<T, U> extends BasicBoss<T, U> {

    var queue:Array<U->Void>;
    var started:Bool;

    var countdownTime:Int;
    var countdownTimer:Timer;
    var complainLoudly:Bool;

    public function new(bytes:Bytes, countdownTime:Int = 5000, complainLoudly:Bool = false):Void {
        this.countdownTime = countdownTime;
        this.complainLoudly = complainLoudly;
        started = false;
        queue = [];
        super(bytes);
        startup();
    }

    public function addWork(work:T, recip:U->Void):Void {
        queue.push(recip);
        send(work);
        cancelCountdown();
        startup();
    }

    #if flash
        override function onIncoming(data:Dynamic):Void {
            while (incoming.messageAvailable) super.onIncoming(data);
        }
    #end

    override function receive(data:U):Void {
        queue.shift()(data);
        if (queue.length == 0) beginCountdown();
    }

    override function onErrorIncoming(error:Dynamic):Void if (complainLoudly) throw error;

    function startup():Void {
        if (!started) {
            started = true;
            start();
        }
    }

    inline function beginCountdown():Void {
        countdownTimer = new Timer(countdownTime);
        countdownTimer.run = onCountdown;
    }

    inline function onCountdown():Void {
        countdownTimer = null;
        die();
        started = false;
    }

    inline function cancelCountdown():Void {
        if (countdownTimer != null) {
            countdownTimer.stop();
            countdownTimer = null;
        }
    }
}
