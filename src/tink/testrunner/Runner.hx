package tink.testrunner;

import tink.testrunner.Case;
import tink.testrunner.Suite;
import tink.testrunner.Reporter;
import tink.testrunner.Timer;
import tink.testrunner.Service;

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
							runCase(caze, suite.before, suite.after, reporter, timers).handle(function(r) {
								results.push(r);
								next();
							});
						} else {
							suite.shutdown.run().handle(cb.bind({info: suite.info, cases: results}));
						}
					}
					suite.startup.run().handle(next);
					
				} else {
					cb({info: suite.info, cases: []});
				}
			});
		});
	}
	
	static function runCase(caze:Case, before:Service, after:Service, reporter:Reporter, timers:TimerManager):Future<CaseResult> {
		return Future.async(function(cb) {
			reporter.report(CaseStart(caze.info)).handle(function(_) {
				
				before.run().timeout(caze.timeout, timers)
					.next(function(_) return caze.execute().collect().timeout(caze.timeout, timers))
					.next(function(result) return after.run().timeout(caze.timeout, timers).next(function(_) return result))
					.map(function(o) return switch o {
						case Success(assertions): assertions;
						case Failure(e): [Failure(e)];
					})
					.handle(function(o) {
						var results = {
							info: caze.info,
							results: o,
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
	public function errors() {
		var ret = [];
		for(s in this) for(c in s.cases) for(a in c.results)
			switch a {
				case Success(_): // skip
				case Failure(_): ret.push(a);
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
	results:Array<Assertion>,
}