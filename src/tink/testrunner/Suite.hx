package tink.testrunner;

import tink.testrunner.Case;

using tink.CoreApi;

@:forward
abstract Suite(SuiteObject) from SuiteObject to SuiteObject {
	
	@:from
	public static inline function ofCases<T:Case>(cases:Array<T>):Suite
		return new BasicSuite({
			name: [for(c in cases) switch Type.getClass(c) {
				case null: null;
				case c: Type.getClassName(c);
			}].join(', '),
		}, cast cases);
	
	@:from
	public static inline function ofCase(caze:Case):Suite
		return ofCases([caze]);
}

typedef SuiteInfo = {
	name:String,
}

interface SuiteObject {
	var info:SuiteInfo;
	var cases:Array<Case>;
	function startup():Promise<Noise>;
	function before():Promise<Noise>;
	function after():Promise<Noise>;
	function shutdown():Promise<Noise>;
}

class BasicSuite implements SuiteObject {
	static var STUB:Promise<Noise> = Future.sync(Success(Noise));
	
	public var info:SuiteInfo;
	public var cases:Array<Case>;
	
	public function new(info, cases) {
		this.info = info;
		this.cases = cases;
	}
	
	public function startup() return STUB;
	public function before() return STUB;
	public function after() return STUB;
	public function shutdown() return STUB;
}