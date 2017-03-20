package;

import tink.testrunner.*;
import tink.testrunner.Assertion.*;
import tink.testrunner.Case;
import travix.Logger.*;

using tink.CoreApi;


class RunTests {
	static function main() {
		
		var code = 0;
		
		#if (cs || java) // https://github.com/HaxeFoundation/haxe/issues/6106
		function assertEquals(expected:Dynamic, actual:Dynamic, ?pos:haxe.PosInfos) {
		#else
		function assertEquals<T>(expected:T, actual:T, ?pos:haxe.PosInfos) {
		#end
			if(expected != actual) {
				println('${pos.fileName}:${pos.lineNumber}: Expected $expected but got $actual ');
				code++;
			}
		}
		
		var futures = [];
		
		// Test: cast from single case
		var single = new SingleCase();
		futures.push(
			function() return Runner.run(single).map(function(result) {
				assertEquals(0, result.errors().sure().length);
				return Noise;
			})
		);
		
		// Test: cast from multiple cases
		futures.push(
			function() return Runner.run([single, single]).map(function(result) {
				assertEquals(0, result.errors().sure().length);
				return Noise;
			})
		);
		
		var iter = futures.iterator();
		function next() {
			if(iter.hasNext()) iter.next()().handle(next);
			else {
				trace('Exiting with code: $code');
				exit(code);
			}
		}
		next();
	}
}

class SingleCase extends BasicCase {
	override function execute():Assertions {
		return new Assertion(true, 'Dummy');
	}
}