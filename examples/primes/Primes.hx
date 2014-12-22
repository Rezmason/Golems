import net.rezmason.utils.workers.QuickBoss;
import net.rezmason.utils.workers.Golem;

typedef PIGBoss = QuickBoss<Int, Array<Int>>;

class Primes
{
    static var pig:PIGBoss = null;
    static var done:Bool = false;

    static function main():Void {
        pig = new PIGBoss(Golem.rise('primes_golems.hxml'), onPrimes, null);
        pig.start();
        pig.send(100);

        #if (neko || cpp) while (!done) {} #end
    }

    static function onPrimes(primes:Array<Int>):Void {
        trace(primes.join('\n'));
        pig.die();
        done = true;
        trace("That'll do pig, that'll do");
    }
}
