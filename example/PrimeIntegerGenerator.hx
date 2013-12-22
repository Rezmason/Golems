import net.rezmason.utils.workers.BasicWorker;

class PrimeIntegerGenerator extends BasicWorker<Int, Int> {

    static var begun:Bool = false;

    override function receive(data:Int):Void {

        if (begun) return;
        begun = true;

        var n:Int = 1;
        while (true) {

            // Apparently, Flash workers won't terminate if they run too tightly
            #if flash for (i in 0...10000000) {} #end

            n++;
            var isPrime:Bool = true;
            var i:Float = 2;
            var lim:Float = Math.sqrt(n);
            while (i < lim) {
                if (n % i == 0) {
                    isPrime = false;
                    break;
                }
                i++;
            }
            if (isPrime) send(n);
        }
    }
}
