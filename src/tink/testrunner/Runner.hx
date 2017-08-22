package tink.testrunner;

import tink.streams.Stream;
import tink.testrunner.Case;
import tink.testrunner.Suite;
import tink.testrunner.Reporter;
import tink.testrunner.Timer;
import haxe.PosInfos;

using tink.testrunner.Runner.TimeoutHelper;
using tink.CoreApi;

class Runner {
	
	public static function exit(result:BatchResult)
		#if travix travix.Logger.exit
		#elseif (air || air3) untyped __global__["flash.desktop.NativeApplication"].nativeApplication.exit
		#elseif (sys || nodejs) Sys.exit
		#elseif (phantomjs) untyped __js__('phantom').exit
		#else throw "not supported";
		#end (result.summary().failures.length);
	
	public static function run(batch:Batch, ?reporter:Reporter, ?timers:TimerManager):Future<BatchResult> {
		
		if(reporter == null) reporter = new BasicReporter();
		if(timers == null) {
			#if ((haxe_ver >= 3.3) || flash || js || openfl)
				timers = new HaxeTimerManager();
			#end
		}
			
		var includeMode = false;
		for(s in batch.suites) {
			if(includeMode) break;
			for(c in s.cases) if(c.include) {
				includeMode = true;
				break;
			}
		}
		
		return Future.async(function(cb) {
			reporter.report(BatchStart).handle(function(_) {
				var iter = batch.suites.iterator();
				var results:BatchResult = [];
				function next() {
					if(iter.hasNext()) {
						var suite = iter.next();
						runSuite(suite, reporter, timers, includeMode).handle(function(o) {
							results.push(o);
							reporter.report(SuiteFinish(o)).handle(next);
						});
					} else {
						reporter.report(BatchFinish(results)).handle(cb.bind(results));
					}
				}
				next();
			});
		});
	}
	
	
	static function runSuite(suite:Suite, reporter:Reporter, timers:TimerManager, includeMode:Bool):Future<SuiteResult> {
		return Future.async(function(cb) {
			reporter.report(SuiteStart(suite.info)).handle(function(_) {
				var cases = suite.cases.filter(function(c) return !c.exclude && (!includeMode || c.include));
				if(cases.length > 0) {
					var iter = cases.iterator();
					var results = [];
					function next() {
						if(iter.hasNext()) {
							var caze = iter.next();
							runCase(caze, suite, reporter, timers).handle(function(r) {
								results.push(r);
								next();
							});
						} else {
							suite.teardown().handle(function(o) cb({
								info: suite.info,
								result: switch o {
									case Success(_): Success(results);
									case Failure(e): TeardownFailed(e, results);
								}
							}));
						}
					}
					suite.setup().handle(function(o) switch o {
						case Success(_): next();
						case Failure(e): cb({info: suite.info, result: SetupFailed(e)});
					});
					
				} else {
					// skip setup and teardown
					cb({info: suite.info, result: Success([])});
				}
			});
		});
	}
	
	static function runCase(caze:Case, suite:Suite, reporter:Reporter, timers:TimerManager):Future<CaseResult> {
		return Future.async(function(cb) {
			reporter.report(CaseStart(caze.info)).handle(function(_) {
				
				suite.before().timeout(caze.timeout, timers, caze.pos)
					.next(function(_) {
						var assertions = [];
						return caze.execute()
							#if pure .forEach #else .forEachAsync #end(function(a) {
								assertions.push(a);
								return reporter.report(Assertion(a)).map(function(_) return #if pure Resume #else true #end);
							})
							#if pure
							.next(function(o):Outcome<Array<Assertion>, Error> return switch o {
								case Depleted: Success(assertions);
								case Halted(_): throw 'unreachable';
								case Failed(e): Failure(e);
							})
							#else
							.next(function(_) return assertions)
							#end
							.timeout(caze.timeout, timers);
					})
					.next(function(result) return suite.after().timeout(caze.timeout, timers, caze.pos).next(function(_) return result))
					.handle(function(result) {
						var results = {
							info: caze.info,
							results: result,
						}
						reporter.report(CaseFinish(results)).handle(function(_) cb(results));
					});
			});
		});
	}
	
}

class TimeoutHelper {
	public static function timeout<T>(promise:Promise<T>, ms:Int, timers:TimerManager, ?pos:PosInfos):Promise<T> {
		return Future.async(function(cb) {
			var done = false;
			var timer = null;
			var link = promise.handle(function(o) {
				done = true;
				if(timer != null) timer.stop();
				cb(o);
			});
			if(!done && timers != null) {
				timer = timers.schedule(ms, function() {
					link.dissolve();
					cb(Failure(new Error('Timed out after $ms ms', pos)));
				});
			}
		});
	}
}

@:forward
abstract BatchResult(Array<SuiteResult>) from Array<SuiteResult> to Array<SuiteResult> {
	public function summary() {
		var ret = {
			assertions: [],
			failures: [],
		};
		
		function handleCases(cases:Array<CaseResult>)
			for(c in cases) switch c.results {
				case Success(assertions):
					ret.assertions = ret.assertions.concat(assertions);
					ret.failures = ret.failures.concat(
						assertions.filter(function(a) return !a.holds)
							.map(function(a) return AssertionFailed(a))
					);
				case Failure(e):
					ret.failures.push(CaseFailed(e));
			}
		
		for(s in this) switch s.result {
			case Success(cases):
				handleCases(cases);
			case SetupFailed(e):
				ret.failures.push(SuiteFailed(e));
			case TeardownFailed(e, cases): 
			 	handleCases(cases);
				ret.failures.push(SuiteFailed(e));
		}
		
		return ret;
	}
}

typedef SuiteResult = {
	info:SuiteInfo,
	result:SuiteResultType,
}

typedef CaseResult = {
	info:CaseInfo,
	results:Outcome<Array<Assertion>, Error>,
}

enum SuiteResultType {
	Success(cases:Array<CaseResult>);
	SetupFailed(e:Error);
	TeardownFailed(e:Error, cases:Array<CaseResult>);
}

enum FailureType {
	AssertionFailed(assertion:Assertion);
	CaseFailed(err:Error);
	SuiteFailed(err:Error);
}