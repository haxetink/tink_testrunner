package tink.testrunner;

import tink.testrunner.Suite;
import tink.testrunner.Case;
import tink.testrunner.Runner;

#if travix
import travix.Logger.*;
#elseif (sys || nodejs)
import *;
#else
	#error "TODO"
#end



using tink.CoreApi;
using Lambda;
using StringTools;

interface Reporter {
	function report(type:ReportType):Future<Noise>; // reporter cannot fail, so it won't ruin the test
}

enum ReportType {
	RunnerStart;
	SuiteStart(info:SuiteInfo);
	CaseStart(info:CaseInfo);
	CaseFinish(result:CaseResult);
	SuiteFinish(result:SuiteResult);
	RunnerFinish(result:Array<SuiteResult>);
}

class BasicReporter implements Reporter {
	
	var noise = Future.sync(Noise);
	
	public function new() {}
	
	public function report(type:ReportType):Future<Noise> {
		switch type {
			case RunnerStart:
				
			case SuiteStart(info):
				println(' ');
				println(info.name);
				
			case CaseStart(info):
				println(indent(info.description, 2));
				
			case CaseFinish({results: results}):
				switch results {
					case Success(results):
						for(assertion in results)
							println(indent('- Assertion ${assertion.holds ? 'holds' : 'failed'}: ${assertion.description}', 4));
					case Failure(e):
						println(indent('- ${e.toString()}', 4));
			}
				
			case SuiteFinish(result):
				
			case RunnerFinish(result):
				var total = 0;
				var errors = 0;
				for(s in result) {
					for(c in s.cases) switch c.results {
						case Success(assertions):
							total += assertions.length;
							errors += assertions.count(function(a) return !a.holds);
						case Failure(e):
							println(e.toString());
					}
				}
				
				var success = total - errors;
				println(' ');
				println('$total Assertions   $success Success   $errors Errors');
				println(' ');
				
		}
		return noise;
	}
	
	function indent(v:String, i = 0) {
		return v.split('\n')
			.map(function(line) return ''.lpad(' ', i) + line)
			.join('\n');
	}
}