package;

/**
 * The shittiest test suite ever
 */
class Test
{
	public static function readTestData(fileName:String):String
	{
		return sys.io.File.getContent('../../data/${fileName}');
		// return sys.io.File.getContent('./data/${fileName}');
	}

	public static inline function assert(condition:Bool, ?message:String, ?posInfos:haxe.PosInfos):Void
	{
		if (message == null)
			message = 'Assertion failed!';
		if (!condition)
			throw '${posDisplay(posInfos)} ${message}';
	}

	public static inline function assertEquals(actual:Dynamic, expected:Dynamic, ?message:String, ?posInfos:haxe.PosInfos):Void
	{
		if (message == null)
			message = 'Expected "${expected}", got "${actual}"';
		assert(thx.Dynamics.equals(actual, expected), message, posInfos);
	}

	public static inline function assertEqualsUnordered(actual:Array<Dynamic>, expected:Array<Dynamic>, ?message:String, ?posInfos:haxe.PosInfos):Void
	{
		if (message == null)
			message = 'Expected "${expected}", got "${actual}"';
		assert(json.util.ArrayUtil.equalsUnordered(actual, expected), message, posInfos);
	}

	public static inline function assertNotEqualsUnordered(actual:Array<Dynamic>, expected:Array<Dynamic>, ?message:String, ?posInfos:haxe.PosInfos):Void
	{
		if (message == null)
			message = 'Expected "${expected}", got "${actual}"';
		assert(!json.util.ArrayUtil.equalsUnordered(actual, expected), message, posInfos);
	}

	public static inline function assertNotEquals(actual:Dynamic, expected:Dynamic, ?message:String, ?posInfos:haxe.PosInfos):Void
	{
		if (message == null)
			message = 'Expected value to not be "${expected}", but was equal';
		assert(!thx.Dynamics.equals(actual, expected), message, posInfos);
	}

	/**
	 * Assert that a function throws an error, optionally checking against an expected error
	 */
	public static inline function assertError(func:() -> Void, ?expected:Dynamic, ?message:String, ?posInfos:haxe.PosInfos):Void
	{
		try
		{
			func();
			assert(false, message, posInfos);
		}
		catch (e)
		{
			// Success!
			if (expected != null)
			{
				assertEquals(e.toString(), expected, message, posInfos);
			}
		}
	}

	static inline function posDisplay(posInfos:haxe.PosInfos):String
	{
		return '[${posInfos.fileName}:${posInfos.lineNumber}]';
	}
}
