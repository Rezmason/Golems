package net.rezmason.utils.workers;

import haxe.io.Bytes;

#if flash
    import flash.system.MessageChannel;
    import flash.system.Worker;
    import flash.system.WorkerDomain;
#elseif cpp
    import cpp.vm.Thread;
#elseif neko
    import neko.vm.Thread;
#end

#if (flash || js)
    typedef Core<T, U> = Bytes;
#elseif (neko || cpp)
    typedef Core<T, U> = Class<BasicWorker<T, U>>;
    typedef Worker = Thread;
#end

class BasicBoss<T, U> {

    var worker:Worker;

    #if flash
        var incoming:MessageChannel;
        var outgoing:MessageChannel;
    #end

    public function new(core:Core<T, U>):Void {
        #if flash
            worker = WorkerDomain.current.createWorker(core.getData());
            incoming = worker.createMessageChannel(Worker.current);
            outgoing = Worker.current.createMessageChannel(worker);
            worker.setSharedProperty('incoming', outgoing);
            worker.setSharedProperty('outgoing', incoming);
            incoming.addEventListener('channelMessage', onIncoming);
        #elseif js
            var blob = new Blob([core.toString()]);
            var url:String = untyped __js__('window').URL.createObjectURL(blob);
            worker = new Worker(url);
            worker.addEventListener('message', onIncoming);
        #elseif (neko || cpp)
            worker = encloseInstance(core, onIncoming);
        #end
    }

    public function start():Void {
        #if flash
            worker.start();
        #end
    }

    public function die():Void {
        #if (flash || js)
            worker.terminate();
        #elseif (neko || cpp)
            worker.sendMessage('__die__');
        #end
    }

    public function send(data:T):Void {
        #if flash
            outgoing.send(data);
        #elseif js
            worker.postMessage(data);
        #elseif (neko || cpp)
            worker.sendMessage(data);
        #end
    }

    function receive(data:U):Void {}

    function onIncoming(data:Dynamic):Void {
        #if flash
            data = incoming.receive();
        #elseif js
            data = data.data;
        #end

        if (Reflect.hasField(data, '__error')) onErrorIncoming(data.__error);
        else receive(data);
    }

    function onErrorIncoming(error:Dynamic):Void throw error;

    #if (neko || cpp)
        static function encloseInstance<T, U>(clazz:Class<BasicWorker<T, U>>, incoming:Dynamic->Void):Thread {
            function func():Void {
                var __clazz:Class<BasicWorker<T, U>> = Thread.readMessage(true);
                var __outgoing:U->Void = Thread.readMessage(true);
                var instance:BasicWorker<T, U> = Type.createInstance(__clazz, []);
                instance.breathe(Thread.readMessage.bind(true), __outgoing);
            }

            var thread:Thread = Thread.create(func);
            thread.sendMessage(clazz);
            thread.sendMessage(incoming);

            return thread;
        }
    #end
}

#if js
    @:native("Blob")
    extern class Blob {
       public function new(strings:Array<String> ) : Void;
    }

    @:native("Worker")
    extern class Worker {
        public function new(script:String):Void;
        public function postMessage(msg:Dynamic):Void;
        public function addEventListener(type:Dynamic, cb:Dynamic->Void):Void;
        public function terminate():Void;
    }
#end
