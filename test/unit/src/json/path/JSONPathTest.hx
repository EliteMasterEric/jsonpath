package json.path;

import json.path.JSONPath;
import json.path.JSONPath.Element;
import json.JSONData;

class JSONPathTest
{
    public static function test():Void {
        testNormalizedPath();
        testQueryPaths();
        testBookstore();
        testComparison();

        trace('JSONPathTest: Done.');
    }

    public static function testNormalizedPath():Void {
        var result = JSONPath.splitNormalizedPath("$");
        Test.assertEqualsUnordered(result, []);

        var result = JSONPath.splitNormalizedPath("$[0]");
        Test.assertEqualsUnordered(result, ['0']);

        var result = JSONPath.splitNormalizedPath("$[0]['k']");
        Test.assertEqualsUnordered(result, ['0', 'k']);

        var result = JSONPath.splitNormalizedPath("$['k'][0]['l']");
        Test.assertEqualsUnordered(result, ['k', '0', 'l']);
    }

    public static function testQueryPaths():Void
    {
        var data = JSONData.parse('{"k": "v"}');

        // From 2.2.3.

        var resultPaths = JSONPath.queryPaths('$', data);
        var result = JSONPath.query('$', data);
        Test.assertEqualsUnordered(resultPaths, ['$']);
        Test.assertEqualsUnordered(result, [{"k": "v"}]);

        var resultPaths = JSONPath.queryPaths('$.k', data);
        var result = JSONPath.query('$.k', data);
        Test.assertEqualsUnordered(resultPaths, ["$['k']"]);
        Test.assertEqualsUnordered(result, ["v"]);

        var data = JSONData.parse('{"k": null}');

        var resultPaths = JSONPath.queryPaths('$.k', data);
        var result = JSONPath.query('$.k', data);
        Test.assertEqualsUnordered(resultPaths, ["$['k']"]);
        Test.assertEqualsUnordered(result, [null]);

        var data = JSONData.parse('{"a": {"b": "c"}}');

        var resultPaths = JSONPath.queryPaths('$.a.b', data);
        var result = JSONPath.query('$.a.b', data);
        Test.assertEqualsUnordered(resultPaths, ["$['a']['b']"]);
        Test.assertEqualsUnordered(result, ["c"]);

        var data = JSONData.parse('[3, 4, 5, 6, 7]');

        var resultPaths = JSONPath.queryPaths('$[0]', data);
        var result = JSONPath.query('$[0]', data);
        Test.assertEqualsUnordered(resultPaths, ["$[0]"]);
        Test.assertEqualsUnordered(result, [3]);

        var resultPaths = JSONPath.queryPaths('$[1]', data);
        var result = JSONPath.query('$[1]', data);
        Test.assertEqualsUnordered(resultPaths, ["$[1]"]);
        Test.assertEqualsUnordered(result, [4]);

        var resultPaths = JSONPath.queryPaths('$.*', data);
        var result = JSONPath.query('$.*', data);
        Test.assertEqualsUnordered(resultPaths, ["$[0]", "$[1]", "$[2]", "$[3]", "$[4]"]);
        Test.assertEqualsUnordered(result, [3, 4, 5, 6, 7]);

        var resultPaths = JSONPath.queryPaths('$[-1]', data);
        var result = JSONPath.query('$[-1]', data);
        Test.assertEqualsUnordered(resultPaths, ["$[4]"]);
        Test.assertEqualsUnordered(result, [7]);

        var resultPaths = JSONPath.queryPaths('$[1:2]', data);
        var result = JSONPath.query('$[1:2]', data);
        Test.assertEqualsUnordered(resultPaths, ["$[1]"]);
        Test.assertEqualsUnordered(result, [4]);

        var resultPaths = JSONPath.queryPaths('$[1:4]', data);
        var result = JSONPath.query('$[1:4]', data);
        Test.assertEqualsUnordered(resultPaths, ["$[1]", "$[2]", "$[3]"]);
        Test.assertEqualsUnordered(result, [4, 5, 6]);

        var resultPaths = JSONPath.queryPaths('$[1:4:2]', data);
        var result = JSONPath.query('$[1:4:2]', data);
        Test.assertEqualsUnordered(resultPaths, ["$[1]", "$[3]"]);
        Test.assertEqualsUnordered(result, [4, 6]);

        // From 2.3.1.3

        var data = JSONData.parse('{
            "o": {"j j": {"k.k": 3}},
            "\'": {"@": 2}
        }');

        var resultPaths = JSONPath.queryPaths("$.o['j j']", data);
        var result = JSONPath.query("$.o['j j']", data);
        Test.assertEqualsUnordered(resultPaths, ["$['o']['j j']"]);
        Test.assertEqualsUnordered(result, [{"k.k": 3}]);

        var resultPaths = JSONPath.queryPaths("$.o['j j']['k.k']", data);
        var result = JSONPath.query("$.o['j j']['k.k']", data);
        Test.assertEqualsUnordered(resultPaths, ["$['o']['j j']['k.k']"]);
        Test.assertEqualsUnordered(result, [3]);

        var resultPaths = JSONPath.queryPaths('$.o["j j"]["k.k"]', data);
        var result = JSONPath.query('$.o["j j"]["k.k"]', data);
        Test.assertEqualsUnordered(resultPaths, ["$['o']['j j']['k.k']"]);
        Test.assertEqualsUnordered(result, [3]);

        var resultPaths = JSONPath.queryPaths('$["\'"]["@"]', data);
        var result = JSONPath.query('$["\'"]["@"]', data);
        Test.assertEqualsUnordered(resultPaths, ["$[''']['@']"]);
        Test.assertEqualsUnordered(result, [2]);

        // From 2.3.2.3

        var data = JSONData.parse('{
            "o": {"j": 1, "k": 2},
            "a": [5, 3]
        }');

        var resultPaths = JSONPath.queryPaths("$[*]", data);
        var result = JSONPath.query("$[*]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['a']", "$['o']"]);
        Test.assertEqualsUnordered(result, [[5, 3], {"j": 1, "k": 2}]);

        var resultPaths = JSONPath.queryPaths("$.o[*]", data);
        var result = JSONPath.query("$.o[*]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['o']['j']", "$['o']['k']"]);
        Test.assertEqualsUnordered(result, [1, 2]);

        var resultPaths = JSONPath.queryPaths("$.o[*, *]", data);
        var result = JSONPath.query("$.o[*, *]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['o']['j']", "$['o']['k']", "$['o']['j']", "$['o']['k']"]);
        Test.assertEqualsUnordered(result, [1, 2, 1, 2]);

        var resultPaths = JSONPath.queryPaths("$.a[*]", data);
        var result = JSONPath.query("$.a[*]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['a'][0]", "$['a'][1]"]);
        Test.assertEqualsUnordered(result, [5, 3]);

        // From 2.3.3.3

        var data = JSONData.parse('["a", "b"]');

        var resultPaths = JSONPath.queryPaths("$[*]", data);
        var result = JSONPath.query("$[*]", data);
        Test.assertEqualsUnordered(resultPaths, ["$[0]", "$[1]"]);
        Test.assertEqualsUnordered(result, ["a", "b"]);

        var resultPaths = JSONPath.queryPaths("$[0]", data);
        var result = JSONPath.query("$[0]", data);
        Test.assertEqualsUnordered(resultPaths, ["$[0]"]);
        Test.assertEqualsUnordered(result, ["a"]);

        var resultPaths = JSONPath.queryPaths("$[1]", data);
        var result = JSONPath.query("$[1]", data);
        Test.assertEqualsUnordered(resultPaths, ["$[1]"]);
        Test.assertEqualsUnordered(result, ["b"]);

        var resultPaths = JSONPath.queryPaths("$[-2]", data);
        var result = JSONPath.query("$[-2]", data);
        Test.assertEqualsUnordered(resultPaths, ["$[0]"]);
        Test.assertEqualsUnordered(result, ["a"]);

        // From 2.3.4.3

        var data = JSONData.parse('["a", "b", "c", "d", "e", "f", "g"]');

        var resultPaths = JSONPath.queryPaths("$[1:3]", data);
        var result = JSONPath.query("$[1:3]", data);
        Test.assertEqualsUnordered(resultPaths, ["$[1]", "$[2]"]);

        var resultPaths = JSONPath.queryPaths("$[5:]", data);
        var result = JSONPath.query("$[5:]", data);
        Test.assertEqualsUnordered(resultPaths, ["$[5]", "$[6]"]);
        Test.assertEqualsUnordered(result, ["f", "g"]);

        var resultPaths = JSONPath.queryPaths("$[:3]", data);
        var result = JSONPath.query("$[:3]", data);
        Test.assertEqualsUnordered(resultPaths, ["$[0]", "$[1]", "$[2]"]);
        Test.assertEqualsUnordered(result, ["a", "b", "c"]);

        var resultPaths = JSONPath.queryPaths("$[1:5:2]", data);
        var result = JSONPath.query("$[1:5:2]", data);
        Test.assertEqualsUnordered(resultPaths, ["$[1]", "$[3]"]);
        Test.assertEqualsUnordered(result, ["b", "d"]);

        var resultPaths = JSONPath.queryPaths("$[5:1:-2]", data);
        var result = JSONPath.query("$[5:1:-2]", data);
        Test.assertEqualsUnordered(resultPaths, ["$[5]", "$[3]"]);
        Test.assertEqualsUnordered(result, ["f", "d"]);

        var resultPaths = JSONPath.queryPaths("$[::-1]", data);
        var result = JSONPath.query("$[::-1]", data);
        Test.assertEqualsUnordered(resultPaths, ["$[6]", "$[5]", "$[4]", "$[3]", "$[2]", "$[1]", "$[0]"]);
        Test.assertEqualsUnordered(result, ["g", "f", "e", "d", "c", "b", "a"]);

        // From 2.5.1.3

        var data = JSONData.parse('["a", "b", "c", "d", "e", "f", "g"]');

        var resultPaths = JSONPath.queryPaths("$[0, 3]", data);
        var result = JSONPath.query("$[0, 3]", data);
        Test.assertEqualsUnordered(resultPaths, ["$[0]", "$[3]"]);
        Test.assertEqualsUnordered(result, ["a", "d"]);

        var resultPaths = JSONPath.queryPaths("$[0:2, 5]", data);
        var result = JSONPath.query("$[0:2, 5]", data);
        Test.assertEqualsUnordered(resultPaths, ["$[0]", "$[1]", "$[5]"]);
        Test.assertEqualsUnordered(result, ["a", "b", "f"]);

        var resultPaths = JSONPath.queryPaths("$[0, 0]", data);
        var result = JSONPath.query("$[0, 0]", data);
        Test.assertEqualsUnordered(resultPaths, ["$[0]", "$[0]"]);
        Test.assertEqualsUnordered(result, ["a", "a"]);

        // From 2.5.2.3

        var data = JSONData.parse('{
            "o": {"j": 1, "k": 2},
            "a": [5, 3, [{"j": 4}, {"k": 6}]]
        }');

        var resultPaths = JSONPath.queryPaths("$..j", data);
        var result = JSONPath.query("$..j", data);
        Test.assertEqualsUnordered(resultPaths, ["$['o']['j']", "$['a'][2][0]['j']"]);
        Test.assertEqualsUnordered(result, [1, 4]);

        var resultPaths = JSONPath.queryPaths("$..[0]", data);
        var result = JSONPath.query("$..[0]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['a'][0]", "$['a'][2][0]"]);
        Test.assertEqualsUnordered(result, [5, {"j": 4}]);

        var resultPaths = JSONPath.queryPaths("$..[*]", data);
        var result = JSONPath.query("$..[*]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['a']", "$['o']", "$['a'][0]", "$['a'][1]", "$['a'][2]", "$['o']['j']", "$['o']['k']", 
            "$['a'][2][0]", "$['a'][2][1]", "$['a'][2][0]['j']", "$['a'][2][1]['k']"]);
        Test.assertEqualsUnordered(result, [[5, 3, [{"j": 4}, {"k": 6}]], {"j": 1, "k": 2}, 5, 3, [{"j": 4}, {"k": 6}], 1, 2, {"j": 4}, {"k": 6}, 4, 6]);

        var resultPaths = JSONPath.queryPaths("$..o", data);
        var result = JSONPath.query("$..o", data);
        Test.assertEqualsUnordered(resultPaths, ["$['o']"]);
        Test.assertEqualsUnordered(result, [{"j": 1, "k": 2}]);

        var resultPaths = JSONPath.queryPaths("$.o..[*, *]", data);
        var result = JSONPath.query("$.o..[*, *]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['o']['j']", "$['o']['k']", "$['o']['j']", "$['o']['k']"]);
        Test.assertEqualsUnordered(result, [1, 2, 1, 2]);

        var resultPaths = JSONPath.queryPaths("$.a..[0, 1]", data);
        var result = JSONPath.query("$.a..[0, 1]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['a'][0]", "$['a'][2][0]", "$['a'][1]", "$['a'][2][1]"]);
        Test.assertEqualsUnordered(result, [5, {"j": 4}, 3, {"k": 6}]);

        // From 2.6.1

        var data = JSONData.parse('{"a": null, "b": [null], "c": [{}], "null": 1}');

        var resultPaths = JSONPath.queryPaths("$.a", data);
        var result = JSONPath.query("$.a", data);
        Test.assertEqualsUnordered(resultPaths, ["$['a']"]);
        Test.assertEqualsUnordered(result, [null]);

        var resultPaths = JSONPath.queryPaths("$.a[0]", data);
        var result = JSONPath.query("$.a[0]", data);
        Test.assertEqualsUnordered(resultPaths, []);
        Test.assertEqualsUnordered(result, []);

        var resultPaths = JSONPath.queryPaths("$.a.d", data);
        var result = JSONPath.query("$.a.d", data);
        Test.assertEqualsUnordered(resultPaths, []);
        Test.assertEqualsUnordered(result, []);

        var resultPaths = JSONPath.queryPaths("$.b[0]", data);
        var result = JSONPath.query("$.b[0]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['b'][0]"]);
        Test.assertEqualsUnordered(result, [null]);

        var resultPaths = JSONPath.queryPaths("$.b[*]", data);
        var result = JSONPath.query("$.b[*]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['b'][0]"]);
        Test.assertEqualsUnordered(result, [null]);

        var resultPaths = JSONPath.queryPaths("$.null", data);
        var result = JSONPath.query("$.null", data);
        Test.assertEqualsUnordered(resultPaths, ["$['null']"]);
        Test.assertEqualsUnordered(result, [1]);

        // TODO: Implement these.
        // var resultPaths = JSONPath.queryPaths("$.b[?@]", data);
        // var resultPaths = JSONPath.queryPaths("$.b[?@==null]", data);
        // var resultPaths = JSONPath.queryPaths("$.c[?@.d==null]", data);

        // From 2.3.5.3

        var data = JSONData.parse('
         {
            "a": [3, 5, 1, 2, 4, 6,
                {"b": "j"},
                {"b": "k"},
                {"b": {}},
                {"b": "kilo"}
            ],
            "o": {"p": 1, "q": 2, "r": 3, "s": 5, "t": {"u": 6}},
            "e": "f"
        }');
        
        var resultPaths = JSONPath.queryPaths("$.a.*", data);
        var result = JSONPath.query("$.a.*", data);
        Test.assertEqualsUnordered(resultPaths, ["$['a'][0]", "$['a'][1]", "$['a'][2]", "$['a'][3]", "$['a'][4]", "$['a'][5]", "$['a'][6]", "$['a'][7]", "$['a'][8]", "$['a'][9]"]);
        Test.assertEqualsUnordered(result, [3, 5, 1, 2, 4, 6, {"b": "j"}, {"b": "k"}, {"b": {}}, {"b": "kilo"}]);

        // Array existance value
        var resultPaths = JSONPath.queryPaths("$.a[?@.b]", data);
        var result = JSONPath.query("$.a[?@.b]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['a'][6]", "$['a'][7]", "$['a'][8]", "$['a'][9]"]);
        Test.assertEqualsUnordered(result, [{"b": "j"}, {"b": "k"}, {"b": {}}, {"b": "kilo"}]);

        // Member value comparison
        var resultPaths = JSONPath.queryPaths("$.a[?@.b == 'kilo']", data);
        var result = JSONPath.query("$.a[?@.b == 'kilo']", data);
        Test.assertEqualsUnordered(resultPaths, ["$['a'][9]"]);
        Test.assertEqualsUnordered(result, [{"b": "kilo"}]);

        // Member value comparison (equivalent enclosed query)
        var resultPaths = JSONPath.queryPaths("$.a[?(@.b == 'kilo')]", data);
        var result = JSONPath.query("$.a[?@.b == 'kilo']", data);
        Test.assertEqualsUnordered(resultPaths, ["$['a'][9]"]);
        Test.assertEqualsUnordered(result, [{"b": "kilo"}]);

        // Array value comparison
        var resultPaths = JSONPath.queryPaths("$.a[?@>3.5]", data);
        var result = JSONPath.query("$.a[?@>3.5]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['a'][1]", "$['a'][4]", "$['a'][5]"]);
        Test.assertEqualsUnordered(result, [5, 4, 6]);

        // Non-singular queries
        var resultPaths = JSONPath.queryPaths("$[?@.*]", data);
        var result = JSONPath.query("$[?@.*]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['a']", "$['o']"]);
        Test.assertEqualsUnordered(result, [[3, 5, 1, 2, 4, 6, {"b": "j"}, {"b": "k"}, {"b": {}}, {"b": "kilo"}], {"p": 1, "q": 2, "r": 3, "s": 5, "t": {"u": 6}}]);

        // Nested filters
        var resultPaths = JSONPath.queryPaths("$[?@[?@.b]]", data);
        var result = JSONPath.query("$[?@[?@.b]]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['a']"]);
        Test.assertEqualsUnordered(result, [[3, 5, 1, 2, 4, 6, {"b": "j"}, {"b": "k"}, {"b": {}}, {"b": "kilo"}]]);

        // Repeated queries
        var resultPaths = JSONPath.queryPaths("$.o[?@<3, ?@<3]", data);
        var result = JSONPath.query("$.o[?@<3, ?@<3]", data);
        Test.assertEqualsUnordered(resultPaths, ["$['o']['p']", "$['o']['q']", "$['o']['p']", "$['o']['q']"]);
        Test.assertEqualsUnordered(result, [1, 2, 1, 2]);

        // Logical OR
        var resultPaths = JSONPath.queryPaths('$.a[?@<2 || @.b == "k"]', data);
        var result = JSONPath.query('$.a[?@<2 || @.b == "k"]', data);
        Test.assertEqualsUnordered(resultPaths, ["$['a'][2]", "$['a'][7]"]);
        Test.assertEqualsUnordered(result, [1, {"b": "k"}]);

        // Object value logical AND
        var resultPaths = JSONPath.queryPaths('$.o[?@>1 && @<4]', data);
        var result = JSONPath.query('$.o[?@>1 && @<4]', data);
        Test.assertEqualsUnordered(resultPaths, ["$['o']['q']", "$['o']['r']"]);
        Test.assertEqualsUnordered(result, [2, 3]);

        // Object value logical OR
        var resultPaths = JSONPath.queryPaths('$.o[?@.u || @.x]', data);
        var result = JSONPath.query('$.o[?@.u || @.x]', data);
        Test.assertEqualsUnordered(resultPaths, ["$['o']['t']"]);
        Test.assertEqualsUnordered(result, [{"u": 6}]);

        // Comparision of queries with no values
        var resultPaths = JSONPath.queryPaths('$.a[?@.b == $.x]', data);
        var result = JSONPath.query('$.a[?@.b == $.x]', data);
        Test.assertEqualsUnordered(resultPaths, ["$['a'][0]", "$['a'][1]", "$['a'][2]", "$['a'][3]", "$['a'][4]", "$['a'][5]"]);
        Test.assertEqualsUnordered(result, [3, 5, 1, 2, 4, 6]);

        // Comparisons of primitive and of structured values
        var resultPaths = JSONPath.queryPaths('$.a[?@ == @]', data);
        var result = JSONPath.query('$.a[?@ == @]', data);
        Test.assertEqualsUnordered(resultPaths, ["$['a'][0]", "$['a'][1]", "$['a'][2]", "$['a'][3]", "$['a'][4]", "$['a'][5]", "$['a'][6]", "$['a'][7]", "$['a'][8]", "$['a'][9]"]);
        Test.assertEqualsUnordered(result, [3, 5, 1, 2, 4, 6, {"b": "j"}, {"b": "k"}, {"b": {}}, {"b": "kilo"}]);

        // TODO: Implement these.

        // var resultPaths = JSONPath.queryPaths('$.a[?match(@.b, "[jk]")]', data);
        // var resultPaths = JSONPath.queryPaths('$.a[?search(@.b, "[jk]")]', data);
    }

    public static function testBookstore():Void {
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

        // The authors of all the books in the bookstore
        var resultPaths = JSONPath.queryPaths('$.store.book[*].author', books);
        Test.assertEqualsUnordered(resultPaths, ["$['store']['book'][0]['author']", "$['store']['book'][1]['author']", "$['store']['book'][2]['author']", "$['store']['book'][3]['author']"]);

        // All authors
        var resultPaths = JSONPath.queryPaths('$..author', books);
        Test.assertEqualsUnordered(resultPaths, ["$['store']['book'][0]['author']", "$['store']['book'][1]['author']", "$['store']['book'][2]['author']", "$['store']['book'][3]['author']"]);

        // All things in the store, which are some books and a bicycle
        var resultPaths = JSONPath.queryPaths('$.store.*', books);
        Test.assertEqualsUnordered(resultPaths, ["$['store']['book']", "$['store']['bicycle']"]);

        // The prices of everything in the store
        var resultPaths = JSONPath.queryPaths('$.store..price', books);
        Test.assertEqualsUnordered(resultPaths, ["$['store']['book'][0]['price']", "$['store']['book'][1]['price']", "$['store']['book'][2]['price']", "$['store']['book'][3]['price']", "$['store']['bicycle']['price']"]);

        // The third book
        var resultPaths = JSONPath.queryPaths('$..book[2]', books);
        Test.assertEqualsUnordered(resultPaths, ["$['store']['book'][2]"]);

        // The third book's author
        var resultPaths = JSONPath.queryPaths('$..book[2].author', books);
        Test.assertEqualsUnordered(resultPaths, ["$['store']['book'][2]['author']"]);

        // Empty result: the third book does not have a "publisher" member
        var resultPaths = JSONPath.queryPaths('$..book[2].publisher', books);
        Test.assertEqualsUnordered(resultPaths, []);

        // The last book in order
        var resultPaths = JSONPath.queryPaths('$..book[-1]', books);
        Test.assertEqualsUnordered(resultPaths, ["$['store']['book'][3]"]);

        // The first two books
        var resultPaths = JSONPath.queryPaths('$..book[0,1]', books);
        Test.assertEqualsUnordered(resultPaths, ["$['store']['book'][0]", "$['store']['book'][1]"]);

        var resultPaths = JSONPath.queryPaths('$..book[:2]', books);
        Test.assertEqualsUnordered(resultPaths, ["$['store']['book'][0]", "$['store']['book'][1]"]);

        // All books with an ISBN number
        var resultPaths = JSONPath.queryPaths('$..book[?(@.isbn)]', books);
        Test.assertEqualsUnordered(resultPaths, ["$['store']['book'][2]", "$['store']['book'][3]"]);

        // All books cheaper than 10
        var resultPaths = JSONPath.queryPaths('$..book[?(@.price<10)]', books);
        Test.assertEqualsUnordered(resultPaths, ["$['store']['book'][0]", "$['store']['book'][2]"]);

        // All books cheaper than the "expensive" value
        var resultPaths = JSONPath.queryPaths('$..book[?(@.price<$.expensive)]', books);
        Test.assertEqualsUnordered(resultPaths, ["$['store']['book'][0]", "$['store']['book'][2]"]);

        // All member values and array elements contained in the input value
        var resultPaths = JSONPath.queryPaths('$..*', books);
        Test.assertEqualsUnordered(resultPaths, ["$['expensive']", "$['store']", 
            "$['store']['bicycle']",
            "$['store']['book']",
                "$['store']['bicycle']['price']", "$['store']['bicycle']['color']", 
                "$['store']['book'][0]",
                "$['store']['book'][1]",
                "$['store']['book'][2]",
                "$['store']['book'][3]",
                    "$['store']['book'][0]['title']", "$['store']['book'][0]['category']", "$['store']['book'][0]['price']", "$['store']['book'][0]['author']",
                    "$['store']['book'][1]['title']", "$['store']['book'][1]['category']", "$['store']['book'][1]['price']", "$['store']['book'][1]['author']",
                    "$['store']['book'][2]['title']", "$['store']['book'][2]['category']", "$['store']['book'][2]['price']", "$['store']['book'][2]['author']", "$['store']['book'][2]['isbn']",
                    "$['store']['book'][3]['title']", "$['store']['book'][3]['category']", "$['store']['book'][3]['price']", "$['store']['book'][3]['author']", "$['store']['book'][3]['isbn']"
        ]);
    } 
}