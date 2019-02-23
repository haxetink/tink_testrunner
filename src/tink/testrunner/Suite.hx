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
		
	public function getCasesToBeRun(includeMode:Bool) {
		return this.cases.filter(function(c) return c.shouldRun(includeMode));
	}
}

typedef SuiteInfo = {
	name:String,
}

interface SuiteObject {
	var info:SuiteInfo;
	var cases:Array<Case>;
	function setup():Promise<Noise>;
	function before():Promise<Noise>;
	function after():Promise<Noise>;
	function teardown():Promise<Noise>;
}

class BasicSuite implements SuiteObject {
	public var info:SuiteInfo;
	public var cases:Array<Case>;
	
	public function new(info, cases) {
		this.info = info;
		this.cases = cases;
		for(c in cases) c.suite = this;
	}
	
	public function setup() return Promise.NOISE;
	public function before() return Promise.NOISE;
	public function after() return Promise.NOISE;
	public function teardown() return Promise.NOISE;
}