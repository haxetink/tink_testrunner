# Assertion

## Basic Assertion

An assertion is described by the `Assertion` class.
It contains the assertion result, a human-readable description and the Haxe source position.

```haxe
class Assertion {
	public var holds(default, null):AssertionResult;
	public var description(default, null):String;
	public var pos(default, null):PosInfos;
}
```

`AssertionResult` is an `Outcome<Noise, String>` where the failure case is a string describling the fail reason.
It is an abstract providing casts from and to `Bool`

```haxe
abstract AssertionResult(Outcome<Noise, String>) from Outcome<Noise, String> to Outcome<Noise, String> {
	@:to public inline function toBool():Bool;
	@:from public static function ofBool(v:Bool):AssertionResult;
	@:from public static function ofOutcome<T>(v:Outcome<T, Error>):AssertionResult;
	
	@:op(!A) inline function not():Bool;
	@:op(A && B) static inline function and_(a:AssertionResult, b:Bool):Bool;
	@:op(A || B) static inline function or_(a:AssertionResult, b:Bool):Bool;
	@:op(A && B) static inline function _and(a:Bool, b:AssertionResult):Bool;
	@:op(A || B) static inline function _or(a:Bool, b:AssertionResult):Bool;
}
```

So, to contruct an `Assertion` instance, one can pass in either a boolean or outcome as the `holds` value:

```haxe
new Assertion(true, 'A passed assertion');
new Assertion(false, 'A failed assertion');
new Assertion(Failure('fail reason'), 'A failed assertion with reason');
```