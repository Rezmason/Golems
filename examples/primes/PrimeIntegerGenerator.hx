import net.rezmason.utils.workers.BasicWorker;

class PrimeIntegerGenerator extends BasicWorker<Int, Array<Int>> {

    override function process(max) return [for (n in 1...max) if (isPrime(n)) n];

    inline function isPrime(n) {
        var succeeds:Bool = true;
        var i:Float = 2;
        var lim:Float = Math.sqrt(n);
        while (i < lim) {
            if (n % i == 0) {
                succeeds = false;
                break;
            }
            i++;
        }
        return succeeds;
    }
}
