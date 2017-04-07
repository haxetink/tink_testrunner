package tink.testrunner;

import haxe.PosInfos;

interface Case {
	var info:CaseInfo;
	var timeout:Int;
	var include:Bool;
	var exclude:Bool;
	var pos:PosInfos;
	function execute():Assertions;
}

typedef CaseInfo = {
	description:String,
}

class BasicCase implements Case {
	public var info:CaseInfo;
	public var timeout:Int = 5000;
	public var include:Bool = false;
	public var exclude:Bool = false;
	public var pos:PosInfos = null;
	
	public function new() {
		info = {
			description: Type.getClassName(Type.getClass(this)),
		}
	}
	
	public function execute():Assertions {
		return [].iterator();
	}
}