package tink.testrunner;

interface Case {
	var info:CaseInfo;
	var timeout:Int;
	var include:Bool;
	var exclude:Bool;
	function execute():Assertions;
}

typedef CaseInfo = {
	description:String,
	timeout:Null<Int>, // ms
}

class BasicCase implements Case {
	public var info:CaseInfo;
	public var timeout:Int = 0;
	public var include:Bool = false;
	public var exclude:Bool = false;
	
	public function new() {
		info = {
			description: Type.getClassName(Type.getClass(this)),
			timeout: 5000,
		}
	}
	
	public function execute():Assertions {
		return [].iterator();
	}
}