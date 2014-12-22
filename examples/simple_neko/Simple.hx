
import net.rezmason.utils.workers.BasicWorker;
import net.rezmason.utils.workers.QuickBoss;

typedef BossExample = QuickBoss<Int, String>

class Simple {

	public static function main() {

		var start = haxe.Timer.stamp();
		var done = false;
		var boss : BossExample = null;
		var last:Int = 0;
		var now:Int = 0;

		function bossReceive(data:String) {
			if (data == 'done') done = true;
			else trace('\t\t\t\t$data');
		}

		while(!done) {

			now = Std.int(haxe.Timer.stamp() - start);
			if (now != last) {
				trace('main clock: $now');
				last = now;
			}

			// > 2 seconds in, create a worker
			if(now >= 2 && boss == null) {
				trace('boss starting');
				boss = new BossExample( WorkerExample, bossReceive );
				boss.start();
				boss.send(0);
			}
		}

		boss.die();
		trace('done');
	}
}

class WorkerExample extends BasicWorker<Int,String> {
	override function process(data:Int):String {
		var work = '';
		var last:Int = 0;
		var now:Int = 0;

		work += 'work starting\n';
		var start = haxe.Timer.stamp();
		var done = false;

		while(!done) {
			now = Std.int(haxe.Timer.stamp() - start);
			if(now != last) {
				work += 'work clock: $now\n';
				last = now;
			}

			// > 2 seconds in, finish the work
			if(now >= 2) {
				done = true;
				work += 'work done\n';
			}
		}

		work += 'done\n';
		return work;
	}
}
