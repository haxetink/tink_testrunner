package tink.testrunner;

import haxe.PosInfos;

using tink.CoreApi;

class Assertion {
	
	public var holds(default, null):Bool;
	public var description(default, null):String;
	public var pos(default, null):PosInfos;

	public function new(holds, description, ?pos:PosInfos) {
		this.holds = holds;
		this.description = description;
		this.pos = pos;
	}

}
