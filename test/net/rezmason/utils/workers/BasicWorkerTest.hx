package net.rezmason.utils.workers;

import haxe.Resource;

import massive.munit.Assert;
import massive.munit.async.AsyncFactory;

class BasicWorkerTest
{

    public function new()
    {

    }

    @Test
    public function constructTest():Void
    {
        var agency:TestWorkerAgency = new TestWorkerAgency(null, null);
        agency.start();
        agency.die();
    }

    @AsyncTest
    public function volleyTest(factory:AsyncFactory):Void
    {
        var agency:TestWorkerAgency = null;
        var last:Int = 0;
        var max:Int = 10;

        var resultHandler = factory.createHandler(this, function() {}, 1000);

        function onReceive(val:String):Void {
            var i:Int = Std.parseInt(val);
            Assert.areEqual(last, i);
            if (i == max) {
                agency.die();
                resultHandler();
            } else {
                last++;
                agency.send(last);
            }
        }

        agency = new TestWorkerAgency(onReceive, null);
        agency.start();
        agency.send(last);
    }

    @AsyncTest
    public function errorTest(factory:AsyncFactory):Void
    {
        var agency:TestWorkerAgency = null;

        var resultHandler = factory.createHandler(this, function() {}, 1000);

        function onError():Void {
            agency.die();
            resultHandler();
        }

        agency = new TestWorkerAgency(null, onError);
        agency.start();
        agency.send(-1);
    }
}

class TestWorkerAgency extends BasicBoss<Int, String> {

    var onReceive:String->Void;
    var onError:Void->Void;

    public function new(onReceive:String->Void, onError:Void->Void):Void {
        super(Golem.rise('testWorker.hxml'));
        this.onReceive = onReceive;
        this.onError = onError;
    }

    override function receive(data:String):Void onReceive(Std.string(data));
    override function onErrorIncoming(error:Dynamic):Void onError();
}
