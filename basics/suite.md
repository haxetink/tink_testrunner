# Suite

```haxe
interface Suite {
	var info:SuiteInfo;
	var cases:Array<Case>;
	function setup():Promise<Noise>;
	function before():Promise<Noise>;
	function after():Promise<Noise>;
	function teardown():Promise<Noise>;
}
```

### Info

!> This section is incomplete, contribute using the button at the bottom of the page

### Controls

The `Suite` interface defines a few functions that will be excuted by the `Runner`
at certain timing:

```haxe
/** Runs once before running any cases in this suite **/
function setup():Promise<Noise>;
/** Runs before every case**/
function before():Promise<Noise>;
/** Runs after every case**/
function after():Promise<Noise>;
/** Runs once after all cases in this suite **/
function teardown():Promise<Noise>;
```