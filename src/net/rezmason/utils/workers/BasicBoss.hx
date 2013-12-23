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
    typedef Core<TInput, TOutput> = Bytes;
#elseif (neko || cpp)
    typedef Core<TInput, TOutput> = Class<BasicWorker<TInput, TOutput>>;
    typedef Worker = Thread;
#end

class BasicBoss<TInput, TOutput> {

    var worker:Worker;

    #if flash
        var incoming:MessageChannel;
        var outgoing:MessageChannel;
    #end

    public function new(core:Core<TInput, TOutput>):Void {
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

    public function send(data:TInput):Void {
        #if flash
            outgoing.send(data);
        #elseif js
            worker.postMessage(data);
        #elseif (neko || cpp)
            worker.sendMessage(data);
        #end
    }

    function receive(data:TOutput):Void {}

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
        static function encloseInstance<TInput, TOutput>(clazz:Class<BasicWorker<TInput, TOutput>>, incoming:Dynamic->Void):Thread {
            function func():Void {
                var __clazz:Class<BasicWorker<TInput, TOutput>> = Thread.readMessage(true);
                var __outgoing:TOutput->Void = Thread.readMessage(true);
                var instance:BasicWorker<TInput, TOutput> = Type.createInstance(__clazz, []);
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
