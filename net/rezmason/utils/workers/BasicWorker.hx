package net.rezmason.utils.workers;

#if flash
    import flash.system.MessageChannel;
    import flash.system.Worker;
    import haxe.Serializer;
    import haxe.Unserializer;
#end

#if js
    import haxe.CallStack;
#end

#if macro
    import haxe.macro.Context;
    import haxe.macro.Expr;
    using Lambda;
#end

#if !macro @:autoBuild(net.rezmason.utils.workers.BasicWorker.build()) #end class BasicWorker<TInput, TOutput> {

    #if flash
        var incoming:MessageChannel;
        var outgoing:MessageChannel;
    #elseif js
        var self:Dynamic;
    #elseif (neko || cpp)
        var outgoing:TOutput->Void;
    #end

    var dead:Bool;

    public function new():Void {
        #if flash
            incoming = Worker.current.getSharedProperty('incoming');
            outgoing = Worker.current.getSharedProperty('outgoing');
            incoming.addEventListener('channelMessage', onIncoming);
        #elseif js
            self = untyped __js__('self');
            self.onmessage = onIncoming;
        #end

        dead = false;
    }

    @:final function onIncoming(input:Dynamic):Void {
        #if flash input = Unserializer.run(incoming.receive());
        #elseif js input = input.data;
        #elseif (neko || cpp) dead = dead || input == '__die__';
        #end

        if (!dead) {
            try {
                var output = process(input);
                #if flash outgoing.send(safeSerialize(output));
                #elseif js self.postMessage(output);
                #elseif (neko || cpp) outgoing(output);
                #end
            } catch (error:Dynamic) {
                var errorData:Dynamic = {__error:error};
                #if flash outgoing.send(safeSerialize(errorData));
                #elseif js self.postMessage(errorData);
                #elseif (neko || cpp) outgoing(errorData);
                #end
            }
        }
    }

    function process(data:TInput):Null<TOutput> return null;

    #if flash
        static inline function safeSerialize(object:Dynamic):String {
            var useCache:Bool = Serializer.USE_CACHE;
            Serializer.USE_CACHE = true;
            var output = Serializer.run(object);
            Serializer.USE_CACHE = useCache;
            return output;
        }
    #end

    #if (neko || cpp)
        @:allow(net.rezmason.utils.workers.BasicBoss)
        function breathe(fetch:Void->TInput, outgoing:TOutput->Void):Void {
            this.outgoing = outgoing;
            while (!dead) onIncoming(fetch());
        }
    #end

    macro public static function build():Array<Field> {
        var fields:Array<Field> = Context.getBuildFields();
        var path:Array<String> = Context.getLocalClass().get().module.split('.');
        var packageName:Array<String> = path.copy();
        var className:String = packageName.pop();

        for (field in fields) {
            if (field.name == 'main' && field.access.has(AStatic)) {
                throw 'Classes that extend BasicWorker cannot declare a static main function.';
            }

            switch (field.kind) {
                case FFun(func) if (field.name == 'new' && func.args.length > 0): {
                    throw 'Classes that extend BasicWorker cannot have constructor arguments.';
                }
                case _:
            }
        }

        // main function
        fields.unshift({
            name:'main',
            access:[APublic, AStatic],
            kind:FFun({
                params:[],
                args:[],
                ret:null,
                expr:macro instance = Type.createInstance($p{path}, []),
            }),
            pos:Context.currentPos(),
        });

        // instance variable
        fields.unshift({
            name:'instance',
            access:[AStatic],
            kind:FVar(null, macro null),
            pos:Context.currentPos(),
        });

        return fields;
    }
}
