package json;

class JSONDataTest
{
	public static function test():Void
	{
		testKeys();

		testBooks();

		trace('JSONDataTest: Done.');
	}

	public static function testKeys():Void
	{
		final TEST_DATA_1:String = '{ "a": 1, "b": 2 }';
		var result1 = JSONData.parse(TEST_DATA_1);
		final TEST_DATA_2:String = '{ "c": 3, "d": 4 }';
		var result2 = JSONData.parse(TEST_DATA_2);
		final TEST_DATA_3:String = '[1, 2, 3]';
		var result3 = JSONData.parse(TEST_DATA_3);

		var result1Keys = result1.keys();
		result1Keys.sort(thx.Dynamics.compare);
		Test.assertEqualsUnordered(result1Keys, ['a', 'b']);

		var result2Keys = result2.keys();
		result2Keys.sort(thx.Dynamics.compare);
		Test.assertEqualsUnordered(result2Keys, ['c', 'd']);

		var result3Keys = result3.keys();
		result3Keys.sort(thx.Dynamics.compare);
		Test.assertEqualsUnordered(result3Keys, ['0', '1', '2']);
		Test.assertNotEqualsUnordered(result3Keys, [0, 1, 2]);
	}

	public static function testBooks():Void
	{
		final TEST_DATA_BOOKS:String = '{
            "store": {
                "book": [
                    {
                        "category": "reference",
                        "author": "Nigel Rees",
                        "title": "Sayings of the Century",
                        "price": 8.95
                    },
                    {
                        "category": "fiction",
                        "author": "Evelyn Waugh",
                        "title": "Sword of Honour",
                        "price": 12.99
                    },
                    {
                        "category": "fiction",
                        "author": "Herman Melville",
                        "title": "Moby Dick",
                        "isbn": "0-553-21311-3",
                        "price": 8.99
                    },
                    {
                        "category": "fiction",
                        "author": "J. R. R. Tolkien",
                        "title": "The Lord of the Rings",
                        "isbn": "0-395-19395-8",
                        "price": 22.99
                    }
                ],
                "bicycle": {
                    "color": "red",
                    "price": 19.95
                }
            },
            "expensive": 10
        }';

		var books = JSONData.parse(TEST_DATA_BOOKS);

		var booksKeys = books.keys();
		booksKeys.sort(thx.Dynamics.compare);
		Test.assertEqualsUnordered(booksKeys, ['expensive', 'store']);
	}

	public static function testNormalizedPath():Void
	{
		final TEST_DATA_1:String = '{ "a": 1, "b": 2 }';

		var data1 = JSONData.parse(TEST_DATA_1);

		var result = data1.getByPath("$['a']");
		Test.assertEquals(result, 1);

		var result = data1.getByPath("$['b']");
		Test.assertEquals(result, 2);
	}
}
