package tink.testrunner;

import tink.testrunner.Case;

using tink.CoreApi;

@:forward
abstract Suite(SuiteObject) from SuiteObject to SuiteObject {
	
	@:from
	public static inline function ofCases<T:Case>(cases:Array<T>):Suite
		return new SuiteObject({
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

class SuiteObject {
	public var info:SuiteInfo;
	public var cases:Array<Case>;
	public var startup:Service;
	public var before:Service;
	public var after:Service;
	public var shutdown:Service;
	
	public function new(info, cases, ?startup, ?before, ?after, ?shutdown) {
		this.info = info;
		this.cases = cases;
		this.startup = startup != null ? startup : Service.dummy;
		this.before = before != null ? before : Service.dummy;
		this.after = after != null ? after : Service.dummy;
		this.shutdown = shutdown != null ? shutdown : Service.dummy;
	}
	
	@:allow(tink.testrunner)
	function includeMode() {
		for(c in cases) if(c.include) return true;
		return false;
	}
}