package tink.testrunner;

import tink.testrunner.Suite;
import tink.testrunner.Case;
import tink.testrunner.Runner;

#if travix
import travix.Logger.*;
#elseif (sys || nodejs)
import Sys.*;
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
	BatchStart;
	SuiteStart(info:SuiteInfo);
	CaseStart(info:CaseInfo);
	Assertion(assertion:Assertion);
	CaseFinish(result:CaseResult);
	SuiteFinish(result:SuiteResult);
	BatchFinish(result:BatchResult);
}

class BasicReporter implements Reporter {
	
	var noise = Future.sync(Noise);
	
	public function new() {}
	
	public function report(type:ReportType):Future<Noise> {
		switch type {
			case BatchStart:
				
			case SuiteStart(info):
				println(' ');
				println(info.name);
				
			case CaseStart(info):
				println(indent(info.description, 2));
				
			case Assertion(assertion):
				println(indent('- Assertion ${assertion.holds ? 'holds' : 'failed'}: ${assertion.description}', 4));
				
			case CaseFinish({results: results}):
				switch results {
					case Success(_):
					case Failure(e):
						println(indent('- ${e.toString()}', 4));
			}
				
			case SuiteFinish(result):
				
			case BatchFinish(result):
				
				var summary = result.summary();
				var total = summary.assertions.length;
				var failures = summary.failures.count(function(f) return f.match(AssertionFailed(_)));
				var success = total - failures;
				var errors = summary.failures.filter(function(f) return !f.match(AssertionFailed(_)));
				println(' ');
				println('$total Assertions   $success Success   $failures failures');
				if(errors.length > 0) for(err in errors) switch err {
					case AssertionFailed(_): // unreachable
					case CaseFailed(e): println('Case Errored: ' + e.toString());
					case SuiteFailed(e): println('Suite Errored: ' + e.toString());
				}
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
