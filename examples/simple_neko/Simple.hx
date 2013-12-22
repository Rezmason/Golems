
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
	override function receive(data:Int):Void {
		var last:Int = 0;
		var now:Int = 0;

		send('work starting');
		var start = haxe.Timer.stamp();
		var done = false;

		while(!done) {
			now = Std.int(haxe.Timer.stamp() - start);
			if(now != last) {
				send('work clock: $now');
				last = now;
			}

			// > 2 seconds in, finish the work
			if(now >= 2) {
				done = true;
				send('work done');
			}
		}

		send('done');
	}
}
