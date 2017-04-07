package tink.testrunner;

import tink.streams.Stream;
import haxe.PosInfos;

using tink.CoreApi;

private typedef Impl = Stream<Assertion, Error>;

@:forward
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
	public static function ofSurpriseAssertion(p:Surprise<Assertion, Error>):Assertions {
		return p >> function(o:Assertion) return ofAssertion(o);
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
}
