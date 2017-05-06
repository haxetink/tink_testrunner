# Quick Start

## Install

### With Haxelib

`haxelib install tink_testrunner`

### With Lix

`lix install haxelib:tink_testrunner`

## A Basic Test

```haxe
import tink.testrunner.*;;

class Main {
	static function main() {
		Runner.run(new TestCase()).handle(Runner.exit);
	}
}

class TestCase extends BasicCase {
	override function execute():Assertions {
		return new Assertion(true, 'Describe the awesome test');
	}
}
```

1. Copy the code above and save it as `Main.hx`
1. Build it with: `haxe -js tests.js -lib hxnodejs -lib tink_testrunner -main Main`
1. Run the test: `node tests.js`
