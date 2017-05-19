# Multiple Assertions

Each test case should return a `Stream<Assertion>`, where `Stream` can be considered as
an async list of items but different to `Array`/`List` that the items may not be available syncronously,
but rather appears over time asyncronously.

There are mainly two ways to proudce multiple assertions in a test.


## Implicit Casts

The first way is to return types that are castable into `Assertions`:

```haxe
abstract Assertions(Stream<Assertion>) from Stream<Assertion> to Stream<Assertion> {
	@:from public static function ofArray(o:Array<Assertion>):Assertions;
}
```

In other words, one can return an array of assertion and let the compiler do the cast job.

## Stream

One can also use stream directly to produce mutliple assertions. [See more here](basics/async-tests.md#stream).