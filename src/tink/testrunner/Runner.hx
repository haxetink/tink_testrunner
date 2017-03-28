package tink.testrunner;

import tink.testrunner.Case;
import tink.testrunner.Suite;
import tink.testrunner.Reporter;
import tink.testrunner.Timer;

using tink.testrunner.Runner.TimeoutHelper;
using tink.CoreApi;

class Runner {
	
	public static function exit(result:BatchResult)
		#if travix travix.Logger.exit
		#elseif sys Sys.exit
		#else #error "not supported"
		#end (result.summary().failures.length);
	
	public static function run(batch:Batch, ?reporter:Reporter, ?timers:TimerManager):Future<BatchResult> {
		
		if(reporter == null) reporter = new BasicReporter();
		if(timers == null)
			// TODO: figure this out: #if (haxe_ver >= 3.4 || js || flash)
			timers = new HaxeTimerManager();
			// TODO: #elseif tink_runloop
			
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
							suite.shutdown().handle(function(o) cb({
								info: suite.info,
								result: switch o {
									case Success(_): Success(results);
									case Failure(e): ShutdownFailed(e, results);
								}
							}));
						}
					}
					suite.startup().handle(function(o) switch o {
						case Success(_): next();
						case Failure(e): cb({info: suite.info, result: StartupFailed(e)});
					});
					
				} else {
					cb({info: suite.info, result: Success([])});
				}
			});
		});
	}
	
	static function runCase(caze:Case, suite:Suite, reporter:Reporter, timers:TimerManager):Future<CaseResult> {
		return Future.async(function(cb) {
			reporter.report(CaseStart(caze.info)).handle(function(_) {
				
				suite.before().timeout(caze.timeout, timers)
					.next(function(_) {
						var assertions = [];
						return caze.execute().forEach(function(a) {
							assertions.push(a);
							reporter.report(Assertion(a));
							return true;
						})
							.map(function(_) return assertions)
							.timeout(caze.timeout, timers);
					})
					.next(function(result) return suite.after().timeout(caze.timeout, timers).next(function(_) return result))
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
	public static function timeout<T>(promise:Promise<T>, ms:Int, timers:TimerManager):Promise<T> {
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
					cb(Failure(new Error('Timed out after $ms ms')));
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
			case StartupFailed(e):
				ret.failures.push(SuiteFailed(e));
			case ShutdownFailed(e, cases): 
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
	StartupFailed(e:Error);
	ShutdownFailed(e:Error, cases:Array<CaseResult>);
}

enum FailureType {
	AssertionFailed(assertion:Assertion);
	CaseFailed(err:Error);
	SuiteFailed(err:Error);
}