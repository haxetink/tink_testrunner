package tink.testrunner;

import haxe.PosInfos;

using tink.CoreApi;

class Assertion {
	
	public var holds(default, null):AssertionResult;
	public var description(default, null):String;
	public var pos(default, null):PosInfos;

	public function new(holds, description, ?pos:PosInfos) {
		this.holds = holds;
		this.description = description;
		this.pos = pos;
	}

}

abstract AssertionResult(Outcome<Noise, String>) from Outcome<Noise, String> to Outcome<Noise, String> {
	@:from
	public static function ofBool(v:Bool):AssertionResult
		return v ? Success(Noise) : Failure('Assertion Failed');
	@:to
	public inline function isSuccess():Bool
		return this.isSuccess();
}