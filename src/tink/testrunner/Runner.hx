package tink.testrunner;

import tink.testrunner.Case;
import tink.testrunner.Suite;
import tink.testrunner.Reporter;
import tink.testrunner.Timer;

using tink.testrunner.Runner.TimeoutHelper;
using tink.CoreApi;

class Runner {
	
	public static function run(batch:Batch, ?reporter:Reporter, ?timers:TimerManager):Future<BatchResult> {
		
		if(reporter == null) reporter = new BasicReporter();
		if(timers == null)
			// TODO: figure this out: #if (haxe_ver >= 3.4 || js || flash)
			timers = new HaxeTimerManager();
			// TODO: #elseif tink_runloop
		
		return Future.async(function(cb) {
			reporter.report(RunnerStart).handle(function(_) {
				var iter = batch.suites.iterator();
				var results:BatchResult = [];
				function next() {
					if(iter.hasNext()) {
						var suite = iter.next();
						runSuite(suite, reporter, timers, batch.includeMode()).handle(function(o) {
							results.push(o);
							reporter.report(SuiteFinish(o)).handle(next);
						});
					} else {
						reporter.report(RunnerFinish(results)).handle(cb.bind(results));
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
							suite.shutdown().handle(cb.bind({info: suite.info, cases: results}));
						}
					}
					suite.startup().handle(next);
					
				} else {
					cb({info: suite.info, cases: []});
				}
			});
		});
	}
	
	static function runCase(caze:Case, suite:Suite, reporter:Reporter, timers:TimerManager):Future<CaseResult> {
		return Future.async(function(cb) {
			reporter.report(CaseStart(caze.info)).handle(function(_) {
				
				suite.before().timeout(caze.timeout, timers)
					.next(function(_) return caze.execute().collect().timeout(caze.timeout, timers))
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
	public function failures() {
		var ret = [];
		for(s in this) for(c in s.cases) switch c.results {
			case Success(assertions):
				ret = ret.concat(
					assertions.filter(function(a) return !a.holds)
						.map(function(a) return FailedAssertion(a))
				);
			case Failure(e):
				ret.push(FailedCase(e));
		}
		return ret;
	}
}

typedef SuiteResult = {
	info:SuiteInfo,
	cases:Array<CaseResult>,
}

typedef CaseResult = {
	info:CaseInfo,
	results:Outcome<Array<Assertion>, Error>,
}

enum FailureType {
	FailedAssertion(assertion:Assertion);
	FailedCase(err:Error);
}