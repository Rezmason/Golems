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
        var boss:TestBoss = new TestBoss(null, null);
        boss.start();
        boss.die();
    }

    @AsyncTest
    public function volleyTest(factory:AsyncFactory):Void
    {
        var boss:TestBoss = null;
        var last:Int = 0;
        var max:Int = 10;

        var resultHandler = factory.createHandler(this, function() {}, 1000);

        function onReceive(val:String):Void {
            var i:Int = Std.parseInt(val);
            Assert.areEqual(last, i);
            if (i == max) {
                boss.die();
                resultHandler();
            } else {
                last++;
                boss.send(last);
            }
        }

        boss = new TestBoss(onReceive, null);
        boss.start();
        boss.send(last);
    }

    @AsyncTest
    public function errorTest(factory:AsyncFactory):Void
    {
        var boss:TestBoss = null;

        var resultHandler = factory.createHandler(this, function() {}, 1000);

        function onError(error:Dynamic):Void {
            boss.die();
            resultHandler();
            Assert.areEqual(error, 'BLARG');
        }

        boss = new TestBoss(null, onError);
        boss.start();
        boss.send(-1);
    }
}

class TestBoss extends QuickBoss<Int, String> {
    public function new(onReceive, onError):Void super(Golem.rise('testWorker.hxml'), onReceive, onError);
}
