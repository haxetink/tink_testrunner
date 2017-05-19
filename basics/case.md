# Case

```haxe
interface Case {
	var info:CaseInfo;
	var timeout:Int;
	var include:Bool;
	var exclude:Bool;
	var pos:PosInfos;
	function execute():Assertions;
}
```

### Info

```haxe
typedef CaseInfo = {
	name:String,
	description:String,
}
```

### Timeout

The case will timeout after the specified number of milliseconds.

### Include / Exclude

If any of the cases has `include` set to true, the `Runner` will trigger `includeMode`.
During `includeMode` is on, the Runner will only execute cases that have `include == true`.

If a case has `exclude` set to true, it will be ignored by the `Runner`

### Pos

Haxe source position of the `Case`.