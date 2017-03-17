package tink.testrunner;

using tink.CoreApi;

@:forward
abstract Services(Array<Service>) from Array<Service> to Array<Service> {
	public function run():Promise<Noise> {
		return Future.async(function(cb) {
			var iter = this.iterator();
			function next() {
				if(iter.hasNext())
					iter.next()().handle(function(o) if(o.isSuccess()) next() else cb(o));
				else
					cb(Success(Noise));
			}
			next();
		});
	}
}

typedef Service = Void->Promise<Noise>;
