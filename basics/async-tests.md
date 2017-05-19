# Async Tests

`tink_testrunner` is built with asynchrony in mind. It can be seen from the fact that
each test case returns `Assertions` which is `Stream<Assertion>` which is actually an
async list of `Assertion`. So, even if the test function is returning a `Assertion`
instance synchronously, it will be casted to a `Stream` (which is async) behind the scene.

## Implicit Casts

In order to write async tests, one can leverage the relevant implicit casts provided by `Assertions`:

```haxe
abstract Assertions(Stream<Assertion>) from Stream<Assertion> to Stream<Assertion> {
	@:from public static function ofFutureAssertion(p:Future<Assertion>):Assertions;
	@:from public static function ofSurpriseAssertion(p:Surprise<Assertion, Error>):Assertions;
	
	@:from public static function ofPromiseArray(o:Promise<Array<Assertion>>):Assertions;
	
	@:from public static function ofFutureAssertions(p:Future<Assertions>):Assertions;
	@:from public static function ofSurpriseAssertions(p:Surprise<Assertions, Error>):Assertions;
	@:from public static function ofPromiseAssertions(p:Promise<Assertions>):Assertions;
}
```


## Assertion Buffer

One can also use an [`AssertionBuffer`](basics/multi-assertions.md#assertion-buffer):

```haxe
public function async() {
	var asserts = new AssertionBuffer();
	var asyncTask().handle(function(o) {
		asserts.assert(o == 'async');
		asserts.done();
	});
	return asserts;
}
```

When using an `AssertionBuffer`, remember to call `done()` on it when the tests are done,
otherwise the tests will never finish and causes a [timeout](#timeout).

### Return the buffer (assertion stream) ASAP

Although the `Assertions` abstract provides implicit casts for Future/Promise of `Assertions`,
it is recommended to return the `Assertions` (or `Stream<Assertion>`) as soon as possible.

Consider the following:

```haxe
public function async() {
	var asserts = new AssertionBuffer();
	return asyncTask().map(function(o) {
		asserts.assert(o == 'async');
		return asserts.done();
	});
}
```

This piece of code looks very similar to the previous one, and they are both valid thanks to the implicit casts.
But there is a fundamental difference:

- The previous code returns the buffer (assertion stream) synchronously and emits the assertion value later
- The code in this section returns a future where the buffer is resolved only after the assertion value is emitted

This might not be a big deal in this particular example. But consider a long-runner async tests with a number of assertions,
the test runner in the previous case will get the buffer immediately, allowing it to report the assertion results as soon
as they are emitted, thus the reporting will be more responsive. For the latter case, the test runner only gain access
to the buffer after all the assertion values has already been produced. This make the reporting "halts" until the buffer 
future is resolved then all assertion results suddenly flood the reporter.


## Timeout

To set a timeout on a test, one can tag the test method with the `@:timeout` metadata:

```haxe
@:timeout(1000) // timeout in 1000 ms
public function async() {...}
```

The default timeout value is 5000ms. One can also tag the metadata at class level so that the timeout
is applied to all test methods in that class.