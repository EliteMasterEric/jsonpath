package json.util;

import json.util.SliceUtil;

class SliceUtilTest
{
	public static function test():Void
	{
		testSlice();

		trace('SliceUtilTest: Done.');
	}

	public static function testSlice():Void
	{
		final DATA_1 = [1, 2, 3, 4, 5];

		var result = SliceUtil.slice(DATA_1, 0, 1);
		Test.assertEquals(result, [1]);

		var result = SliceUtil.slice(DATA_1, 0, 3);
		Test.assertEquals(result, [1, 2, 3]);

		var result = SliceUtil.slice(DATA_1, null, null, null);
		Test.assertEquals(result, [1, 2, 3, 4, 5]);

		var result = SliceUtil.slice(DATA_1, null, null, -1);
		Test.assertEquals(result, [5, 4, 3, 2, 1]);

		final DATA_2 = ["a", "b", "c", "d", "e", "f", "g"];

		var result = SliceUtil.slice(DATA_2, 1, 3);
		Test.assertEquals(result, ["b", "c"]);

		var result = SliceUtil.slice(DATA_2, 5);
		Test.assertEquals(result, ["f", "g"]);

		var result = SliceUtil.slice(DATA_2, 1, 5, 2);
		Test.assertEquals(result, ["b", "d"]);

		var result = SliceUtil.slice(DATA_2, 5, 1, -2);
		Test.assertEquals(result, ["f", "d"]);

		var result = SliceUtil.slice(DATA_2, null, null, -1);
		Test.assertEquals(result, ["g", "f", "e", "d", "c", "b", "a"]);
	}
}
