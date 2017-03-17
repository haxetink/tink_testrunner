package tink.testrunner;

using tink.CoreApi;

private typedef PromiseGenerator = Void->Promise<Noise>;

@:forward
abstract Service(PromiseGenerator) from PromiseGenerator to PromiseGenerator {
	
	static var noise = Future.sync(Success(Noise));
	
	public static function dummy()
		return noise;
	
	@:from
	public static function ofMany(v:Array<PromiseGenerator>):Service {
		return Future.async.bind(function(cb) {
			var iter = v.iterator();
			function next() {
				if(iter.hasNext())
					iter.next()().handle(function(o) if(o.isSuccess()) next() else cb(o));
				else
					cb(Success(Noise));
			}
			next();
		});
	}
	
	public inline function run():Promise<Noise>
		return (this)();
}

