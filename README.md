# tink_testrunner


tink_testrunner logically breaking down a test into several major parts:

### Assertion

An assertion is merely a "success or failure" value. 

It is perfectly represented by `tink.core.Outcome`.

### Assertions

A collection of Assertion. 

A naive repsentation would be `Array<Assertion>`.
But we chose to use `Stream<Assertion>` in order to support async tests.
After all, `Stream` is the async counterpart of `Array`.

### Case

A Case is a function that emits Assertions.

So it is basically `Void->Assertions`. However, in order to support more fine-grain controls
on what tests to be included/excluded, the actual implementation of a Case does include some extra control informations.

```haxe
interface Case {
	var info:CaseInfo; // meta info such as descriptions, etc
	var timeout:Int; // timeout in ms
	var include:Bool; // include only this case while running
	var exclude:Bool; // exclude this case while running
	function execute():Assertions;
}
```

### Suite

A Suite is a collection of Cases.

So basically it is `Array<Case>`. However, we may also want to execute some pre/post actions for a case,
so the actual implementation looks like this:

```haxe
class Suite {
	public var info:SuiteInfo; // meta info
	public var cases:Array<Case>;
	public function startup():Promise<Noise>; // to be run once before all cases
	public function before():Promise<Noise>; // to be run before each cases
	public function after():Promise<Noise>; // to be run after each cases
	public function shutdown():Promise<Noise>; // to be run once after all cases
}
```

### Batch

A Batch is a colllection of Suites.

This time it is really just `Array<Suite>`.

### Runner

A Runner will take a Batch and run it, then emits the results to a reporter.

### Reporter

A Reporter reports the progress of a Runner to user. There is not much to say about it.



