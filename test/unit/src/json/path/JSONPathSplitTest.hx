package json.path;

import json.path.JSONPath;

class JSONPathSplitTest
{
	public static function test():Void
	{
		testNormalizedPath();

		trace('JSONPathSplitTest: Done.');
	}

	public static function testNormalizedPath():Void
	{
		// splitNormalizedPath returns an array of either Left(String) or Right(Int) objects.

		var result = JSONPath.splitNormalizedPath("$");
		Test.assertEqualsUnordered(result, []);

		var result = JSONPath.splitNormalizedPath("$[0]");
		Test.assertEqualsUnordered(result, [Right(0)]);

		var result = JSONPath.splitNormalizedPath("$['0']");
		Test.assertEqualsUnordered(result, [Left('0')]);

		var result = JSONPath.splitNormalizedPath("$[0]['k']");
		Test.assertEqualsUnordered(result, [Right(0), Left('k')]);

		var result = JSONPath.splitNormalizedPath("$['k'][0]['l']");
		Test.assertEqualsUnordered(result, [Left('k'), Right(0), Left('l')]);
	}
}
