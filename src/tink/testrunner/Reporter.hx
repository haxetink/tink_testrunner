package tink.testrunner;

import tink.testrunner.Suite;
import tink.testrunner.Case;
import tink.testrunner.Runner;

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

interface Formatter {
	function success(v:String):String;
	function error(v:String):String;
	function warning(v:String):String;
	function info(v:String):String;
	function color(v:String, color:String):String;
}

class BasicFormatter implements Formatter {
	public function new() {}
	
	public function success(v:String):String
		return color(v, 'green');
	public function error(v:String):String
		return color(v, 'red');
	public function warning(v:String):String
		return color(v, 'yellow');
	public function info(v:String):String
		return color(v, 'yellow');
	public function color(v:String, c:String):String
		return v;
}

#if ansi
class AnsiFormatter extends BasicFormatter {
	override function color(v:String, c:String):String
		return switch c {
			case 'red': ANSI.aset([ANSI.Attribute.Red]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			case 'green': ANSI.aset([ANSI.Attribute.Green]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			case 'yellow': ANSI.aset([ANSI.Attribute.Yellow]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			default: v;
		}
}
#end

class BasicReporter implements Reporter {
	
	var noise = Future.sync(Noise);
	var formatter:Formatter;
	
	public function new(?formatter) {
		this.formatter =
			if(formatter != null)
				formatter;
			else
				#if (ansi && (sys || nodejs))
					switch Sys.systemName() {
						case 'Windows': new BasicFormatter();
						default: new AnsiFormatter();
					}
				#else
					new BasicFormatter();
				#end
	}
	
	public function report(type:ReportType):Future<Noise> {
		switch type {
			case BatchStart:
				
			case SuiteStart(info):
				println(' ');
				println(formatter.info(info.name));
				
			case CaseStart(info):
				println(formatter.info(indent(info.description, 2)));
				
			case Assertion(assertion):
				var m = indent('- Assertion ${assertion.holds ? 'holds' : 'failed'}: ${assertion.description}', 4);
				println(assertion.holds ? m : formatter.error(m));
				
			case CaseFinish({results: results}):
				switch results {
					case Success(_):
					case Failure(e):
						println(formatter.error(indent('- ${e.toString()}', 4)));
			}
				
			case SuiteFinish(result):
				
			case BatchFinish(result):
				
				var summary = result.summary();
				var total = summary.assertions.length;
				var failures = summary.failures.count(function(f) return f.match(AssertionFailed(_)));
				var success = total - failures;
				var errors = summary.failures.filter(function(f) return !f.match(AssertionFailed(_)));
				
				var m = '$total Assertions   $success Success   $failures failures';
				println(' ');
				println(failures == 0 ? formatter.success(m) : formatter.error(m));
				if(errors.length > 0) for(err in errors) switch err {
					case AssertionFailed(_): // unreachable
					case CaseFailed(e): println(formatter.error('Case Errored: ' + e.toString()));
					case SuiteFailed(e): println(formatter.error('Suite Errored: ' + e.toString()));
				}
				println(' ');
				
		}
		return noise;
	}
	
	function println(v:String)
		#if travix
			travix.Logger.println(v);
		#elseif (sys || nodejs)
			Sys.println(v);
		#else
			#error "Not supported yet"
		#end
	
	function indent(v:String, i = 0) {
		return v.split('\n')
			.map(function(line) return ''.lpad(' ', i) + line)
			.join('\n');
	}
}
