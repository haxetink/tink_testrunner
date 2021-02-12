package tink.testrunner;

import tink.streams.Stream;
import haxe.PosInfos;

using tink.CoreApi;

private typedef Impl = Stream<Assertion, Error>;

@:forward @:transitive
abstract Assertions(Impl) from Impl to Impl {
	@:from
	public static inline function ofAssertion(o:Assertion):Assertions {
		return [o].iterator();
	}
	@:from
	public static inline function ofArray(o:Array<Assertion>):Assertions {
		return o.iterator();
	}
	@:from
	public static inline function ofPromiseArray(o:Promise<Array<Assertion>>):Assertions {
		return o.next(function(o):Impl return o.iterator());
	}

	@:from
	public static function ofFutureAssertion(p:Future<Assertion>):Assertions {
		return p.map(function(a) return Success(ofAssertion(a)));
	}

	@:from
	public static function ofFutureAssertions(p:Future<Assertions>):Assertions {
		return p.map(Success);
	}

	@:from
	public static function ofSurpriseAssertion(p:Surprise<Assertion, Error>):Assertions {
		return Promise.lift(p).next(ofAssertion);
	}

	@:from
	public static inline function ofOutcomeAssertions(o:Outcome<Assertions, Error>):Assertions {
		return ofSurpriseAssertions(Future.sync(o));
	}

	@:from
	public static inline function ofPromiseAssertions(p:Promise<Assertions>):Assertions {
		return ofSurpriseAssertions(p);
	}

	@:from
	public static inline function ofSurpriseAssertions(p:Surprise<Assertions, Error>):Assertions {
		return Stream.promise((p:Surprise<Impl, Error>));
	}

	#if tink_unittest
	// TODO: use solution from https://github.com/HaxeFoundation/haxe/issues/9611
	@:from
	public static inline function ofFutureAssertionBuffer(p:Future<tink.unit.AssertionBuffer>):Assertions {
		return ofFutureAssertions(cast p);
	}
	@:from
	public static inline function ofPromiseAssertionBuffer(p:Promise<tink.unit.AssertionBuffer>):Assertions {
		return ofPromiseAssertions(cast p);
	}
	#end
}
