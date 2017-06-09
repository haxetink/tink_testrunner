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
	function extra(v:String):String;
	function mute(v:String):String;
	function normal(v:String):String;
	function color(v:String, color:String):String;
}

class BasicFormatter implements Formatter {
	public function new() {}
	
	public function success(v:String):String return color(v, 'green');
	public function error(v:String):String return color(v, 'red');
	public function warning(v:String):String return color(v, 'yellow');
	public function info(v:String):String return color(v, 'yellow');
	public function extra(v:String):String return color(v, 'cyan');
	public function mute(v:String):String return color(v, 'blue');
	public function normal(v:String):String return color(v, '');
	public function color(v:String, c:String):String return v;
}

#if ansi
class AnsiFormatter extends BasicFormatter {
	override function color(v:String, c:String):String
		return switch c {
			case 'red': ANSI.aset([ANSI.Attribute.Red]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			case 'green': ANSI.aset([ANSI.Attribute.Green]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			case 'blue': ANSI.aset([ANSI.Attribute.Blue]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			case 'yellow': ANSI.aset([ANSI.Attribute.Yellow]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			case 'magenta': ANSI.aset([ANSI.Attribute.Magenta]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			case 'cyan': ANSI.aset([ANSI.Attribute.Cyan]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			default: ANSI.aset([ANSI.Attribute.DefaultForeground]) + v;
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
				var m = formatter.info(indent(info.name, 2)) + ': ';
				if(info.pos != null) m += formatter.extra('[${info.pos.fileName}:${info.pos.lineNumber}] ');
				if(info.description != null) m += formatter.mute(info.description);
				println(m);
				
			case Assertion(assertion):
			
				var failure = null;
				var holds = switch assertion.holds {
					case Success(_): formatter.success('[OK]');
					case Failure(msg):
						failure = msg;
						formatter.error('[FAIL]');
				}
				var pos = formatter.extra('[${assertion.pos.fileName}:${assertion.pos.lineNumber}]');
				var m = indent('- $holds $pos ${assertion.description}', 4);
				println(m);
				if(failure != null) println(formatter.error(indent(failure, 8)));
				
			case CaseFinish({results: results}):
				switch results {
					case Success(_):
					case Failure(e):
						println(formatter.error(indent('- ${e.toString()}', 4)));
			}
				
			case SuiteFinish(result):
			
				switch result.result {
					case Success(_): // ok
					case SetupFailed(e): println(formatter.error(indent('Setup Failed: ${e.toString()}', 2)));
					case TeardownFailed(e, _): println(formatter.error(indent('Teardown Failed: ${e.toString()}', 2)));
				}
				
			case BatchFinish(result):
				
				var summary = result.summary();
				var total = summary.assertions.length;
				var failures = 0, errors = 0;
				for(f in summary.failures) switch f {
					case AssertionFailed(_): failures++;
					default: errors++;
				}
				var success = total - failures;
				
				var m = new StringBuf();
				m.add(total);
				m.add(' Assertion');
				if(total > 1) m.add('s');
				m.add('   ');
				
				m.add(success);
				m.add(' Success');
				m.add('   ');
				
				m.add(failures);
				m.add(' Failure');
				if(failures > 1) m.add('s');
				m.add('   ');
				
				m.add(errors);
				m.add(' Error');
				if(errors > 1) m.add('s');
				m.add('   ');
				
				var m = m.toString();
				
				println(' ');
				println(failures == 0 && errors == 0 ? formatter.success(m) : formatter.error(m));
				println(' ');
				
		}
		return noise;
	}
	
	function println(v:String)
		#if travix
			travix.Logger.println(v);
		#elseif (air || air3)
			flash.Lib.trace(v);
		#elseif (sys || nodejs)
			Sys.println(v);
		#else
			throw "Not supported yet";
		#end
	
	function indent(v:String, i = 0) {
		return v.split('\n')
			.map(function(line) return ''.lpad(' ', i) + line)
			.join('\n');
	}
}
