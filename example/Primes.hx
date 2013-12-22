import net.rezmason.utils.workers.BasicBoss;
import net.rezmason.utils.workers.Golem;

class Primes
{
    static var pig:Boss = null;

    static function main():Void {

        function onPrime(i:Int):Void {
            trace(i);
            if (i > 100) {
                trace("That'll do pig, that'll do");
                pig.die();
            }
        }

        pig = new Boss(onPrime, null);
        pig.start();
        pig.send(0);
    }
}

class Boss extends BasicBoss<Int, Int> {

    var onReceive:Int->Void;
    var onError:Void->Void;

    public function new(onReceive:Int->Void, onError:Void->Void):Void {
        super(Golem.rise('primes.hxml'));
        this.onReceive = onReceive;
        this.onError = onError;
    }

    override function receive(data:Int):Void onReceive(data);
    override function onErrorIncoming(error:Dynamic):Void onError();
}
