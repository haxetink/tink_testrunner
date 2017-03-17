package tink.testrunner;

import haxe.macro.Context;
import haxe.macro.Expr;

class Macro {
	public static macro function makeSuite(e:Expr) {
		var ct = Context.toComplexType(Context.typeof(e));
		return macro new tink.testrunner.impl.TinkSuite.TinkSuiteBuilder<$ct>($e);
	}
}