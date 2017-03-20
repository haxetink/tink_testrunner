package tink.testrunner;

@:forward
abstract Batch(Array<Suite>) from Array<Suite> to Array<Suite> {
	
	public var suites(get, never):Array<Suite>;
	
	public inline function new(suites:Array<Suite>)
		this = suites;
	
	@:from
	public static inline function ofSuites<T:Suite>(suites:Array<T>):Batch
		return new Batch(cast suites);
		
	@:from
	public static inline function ofSuite(suite:Suite):Batch
		return ofSuites([suite]);
	
	@:from
	public static inline function ofCases<T:Case>(cases:Array<T>):Batch
		return ofSuite(cases);
		
	@:from
	public static inline function ofCase(caze:Case):Batch
		return ofCases([caze]);
		
	inline function get_suites()
		return this;
}