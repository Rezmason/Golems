package net.rezmason.utils.workers;

typedef Job<TInput, TOutput> = {work:TInput, recip:TOutput->Void};

class TempAgency<TInput, TOutput> {

    public var onDone:Void->Void;

    var queue:Array<Job<TInput, TOutput>>;
    var temps:Array<QuickBoss<TInput, TOutput>>;
    var idleTemps:Array<QuickBoss<TInput, TOutput>>;
    var activeJobsByTemp:Map<QuickBoss<TInput, TOutput>, Job<TInput, TOutput>>;

    public function new(core, numQuickBosss:Int = 1):Void {
        queue = [];
        temps = [];
        for (i in 0...numQuickBosss) {
            var temp = new QuickBoss(core);
            temp.onReceive = receiveWork.bind(temp);
            temp.start();
            temps.push(temp);
        }
        idleTemps = temps.copy();
        activeJobsByTemp = new Map();
    }

    public function addWork(work:TInput, recip:TOutput->Void):Void {
        queue.push({work:work, recip:recip});
        var temp = idleTemps.pop();
        if (temp != null) assignWork(temp);
    }

    public function die():Void for (temp in temps) temp.die();

    function receiveWork(temp:QuickBoss<TInput, TOutput>, data:TOutput):Void {
        activeJobsByTemp[temp].recip(data);
        assignWork(temp);
    }

    function assignWork(temp:QuickBoss<TInput, TOutput>):Void {
        var job = queue.pop();
        if (job == null) {
            idleTemps.push(temp);
            if (idleTemps.length == temps.length && onDone != null) onDone();
        } else {
            activeJobsByTemp[temp] = job;
            temp.send(job.work);
        }
    }
}
