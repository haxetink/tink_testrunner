package tink.testrunner;

interface Timer {
	function stop():Void;
}

interface TimerManager {
	function schedule(ms:Int, f:Void->Void):Timer;
}

class HaxeTimer implements Timer {
	
	var timer:haxe.Timer;
	
	public function new(ms:Int, f:Void->Void) {
		timer = haxe.Timer.delay(f, ms);
	}
	
	public function stop() {
		if(timer != null) {
			timer.stop();
			timer = null;
		}
	}
}

class HaxeTimerManager implements TimerManager {
	public function new() {}
	
	public function schedule(ms:Int, f:Void->Void):Timer {
		return new HaxeTimer(ms, f);
	}
}