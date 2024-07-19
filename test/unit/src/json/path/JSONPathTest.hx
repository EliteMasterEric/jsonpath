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
        testBugs();
        testErrors();

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

    public static function testBugs():Void {
        // https://cburgmer.github.io/json-path-comparison/results/bracket_notation_with_negative_number_on_short_array.html
        var data:JSONData = ["one element"];
        var resultPaths = JSONPath.queryPaths('$[-2]', data);
        var result = JSONPath.query('$[-2]', data);
        Test.assertEqualsUnordered(resultPaths, []);
        Test.assertEqualsUnordered(result, []);

        // https://cburgmer.github.io/json-path-comparison/results/filter_expression_with_tautological_comparison.html
        var data:JSONData = [1, 3, "nice", true, null, false, {}, [], -1, 0, ""];
        var resultPaths = JSONPath.queryPaths('$[?(1==1)]', data);
        var result = JSONPath.query('$[?(1==1)]', data);
        Test.assertEqualsUnordered(resultPaths, ["$[0]", "$[1]", "$[2]", "$[3]", "$[4]", "$[5]", "$[6]", "$[7]", "$[8]", "$[9]", "$[10]"]);
        Test.assertEqualsUnordered(result, [1, 3, "nice", true, null, false, {}, [], -1, 0, ""]);
        
        // https://cburgmer.github.io/json-path-comparison/results/filter_expression_with_equals_string_in_NFC.html
        var data:JSONData = [
            {"key": "something"},
            {"key": "Mot\u00f6rhead"},
            {"key": "mot\u00f6rhead"},
            {"key": "Motorhead"},
            {"key": "Motoo\u0308rhead"},
            {"key": "motoo\u0308rhead"}
          ];
          var resultPaths = JSONPath.queryPaths('$[?(@.key=="Motörhead")]', data);
          var result = JSONPath.query('$[?(@.key=="Motörhead")]', data);
        Test.assertEqualsUnordered(resultPaths, ["$[1]"]);
        Test.assertEqualsUnordered(result, [{"key": "Mot\u00f6rhead"}]);

        // https://cburgmer.github.io/json-path-comparison/results/filter_expression_with_greater_than_string.html
        var data:JSONData = [
            {"key": 0}, // 0
            {"key": 42},
            {"key": -1},
            {"key": 41},
            {"key": 43},
            {"key": 42.0001},
            {"key": 41.9999},
            {"key": 100},
            {"key": "43"},
            {"key": "42"},
            {"key": "41"}, // 10
            {"key": "alpha"},
            {"key": "ALPHA"},
            {"key": "value"},
            {"key": "VALUE"},
            {"some": "value"},
            {"some": "VALUE"}
        ];
        var resultPaths = JSONPath.queryPaths('$[?(@.key>"VALUE")]', data);
        var result = JSONPath.query('$[?(@.key>"VALUE")]', data);
        Test.assertEqualsUnordered(resultPaths, ["$[11]", "$[13]"]);
        Test.assertEqualsUnordered(result, [{"key": "alpha"}, {"key": "value"}]);

        // https://cburgmer.github.io/json-path-comparison/results/dot_notation_with_number_on_object.html
        var data:JSONData = {"a": "first", "2": "second", "b": "third"};
        var resultPaths = JSONPath.queryPaths('$.2', data);
        var result = JSONPath.query('$.2', data);
        Test.assertEqualsUnordered(resultPaths, ["$['2']"]);
        Test.assertEqualsUnordered(result, ["second"]);

        // https://cburgmer.github.io/json-path-comparison/results/dot_notation_with_non_ASCII_key.html
        // TODO: Haxe does not handle non-ASCII characters in keys
        /*
        var data:JSONData = {
            "屬性": "value"
        };
        var resultPaths = JSONPath.queryPaths('$.屬性', data);
        var result = JSONPath.query('$.屬性', data);
        Test.assertEqualsUnordered(resultPaths, ["$['屬性']"]);
        Test.assertEqualsUnordered(result, ["value"]);
        */

        // https://cburgmer.github.io/json-path-comparison/results/dot_notation_with_dash.html
        var data:JSONData = {
            "key": 42,
            "key-": 43,
            "-": 44,
            "dash": 45,
            "-dash": 46,
            "": 47,
            "key-dash": "value",
            "something": "else"
        };
        var resultPaths = JSONPath.queryPaths('$.key-dash', data);
        var result = JSONPath.query('$.key-dash', data);
        Test.assertEqualsUnordered(resultPaths, ["$['key-dash']"]);
        Test.assertEqualsUnordered(result, ["value"]);
    }

    public static function testErrors():Void {
        // https://cburgmer.github.io/json-path-comparison/results/current_with_dot_notation.html
        var data = { "a": 1 };
        Test.assertError(() -> {
            var result = JSONPath.query('@.a', data);
            trace(result);
        }, 'JSONPath query must start with "$", but got token: At');

        // https://cburgmer.github.io/json-path-comparison/results/dot_bracket_notation.html
        var data = {
            "key": "value",
            "other": {"key": [{"key": 42}]}
        };
        Test.assertError(() -> {
            var result = JSONPath.query("$.['key']", data);
            trace(result);
        }, 'Expected member name or array index after ".", but got token: Brackets([StringLiteral(key)])');

        // https://cburgmer.github.io/json-path-comparison/results/dot_bracket_notation_with_double_quotes.html
        var data = {
            "key": "value",
            "other": {"key": [{"key": 42}]}
        };
        Test.assertError(() -> {
            var result = JSONPath.query('$.["key"]', data);
            trace(result);
        }, 'Expected member name or array index after ".", but got token: Brackets([StringLiteral(key)])');

        // https://cburgmer.github.io/json-path-comparison/results/dot_notation_after_recursive_descent_with_extra_dot.html
        var data1:Array<Dynamic> = [
            {"key": "something"},
            {"key": {"key": "russian dolls"}}
        ];
        var data = {
            "object": {
                "key": "value",
                "array": data1
            },
            "key": "top"
        };
        Test.assertError(() -> {
            var result = JSONPath.query('$...key', data);
            trace(result);
        }, 'Expected member name or array index after "..", but got token: Dot');

        // https://cburgmer.github.io/json-path-comparison/results/dot_notation_with_double_quotes.html
        var data = {
            "key": "value",
            "\"key\"": 42
        };
        Test.assertError(() -> {
            var result = JSONPath.query('$."key"', data);
            trace(result);
        }, 'Expected member name or array index after ".", but got string literal: key');

        // https://cburgmer.github.io/json-path-comparison/results/dot_notation_with_double_quotes_after_recursive_descent.html
        var data1:Array<Dynamic> = [
            {"key": "something", "\"key\"": 0},
            {"key": {"key": "russian dolls"}, "\"key\"": {"\"key\"": 99}}
          ];
        var data = {
            "object": {
              "key": "value",
              "\"key\"": 100,
              "array": data1
            },
            "key": "top",
            "\"key\"": 42
        };
        Test.assertError(() -> {
            var result = JSONPath.query('$.."key"', data);
            trace(result);
        }, 'Expected member name or array index after "..", but got string literal: key');

        //
        // From compliance test suite
        // 

        // whitespace, slice, return between colon and step
        var data = [1, 2, 3, 4, 5, 6];
        var result = JSONPath.query('$[1:5:\r2]', data);
        Test.assertEqualsUnordered(result, [2, 4]);

        // basic, wildcard shorthand, object data
        var data = { "a": "A", "b": "B" };
        var result = JSONPath.query('$.*', data);
        Test.assertEqualsUnordered(result, ["A", "B"]);

        // filter, equals null
        var data = [ { "a": null, "d": "e" }, { "a": "c", "d": "f" } ];
        var result = JSONPath.query('$[?@.a==null]', data);
        Test.assertEqualsUnordered(result, [{ "a": null, "d": "e" }]);

        // filter, equals true
        var data:Array<Dynamic> = [ { "a": true, "d": "e" }, { "a": "c", "d": "f" } ];
        var result = JSONPath.query('$[?@.a==true]', data);
        Test.assertEqualsUnordered(result, [{ "a": true, "d": "e" }]);

        // filter, equals false
        var data:Array<Dynamic> = [ { "a": false, "d": "e" }, { "a": "c", "d": "f" } ];
        var result = JSONPath.query('$[?@.a==false]', data);
        Test.assertEqualsUnordered(result, [{ "a": false, "d": "e" }]);

        // filter, exists or exists, data false
        var data:Array<Dynamic> = [ { "a": false, "b": false }, { "b": false }, { "c": false } ];
        var result = JSONPath.query("$[?@.a||@.b]", data);
        Test.assertEqualsUnordered(result, [{ "a": false, "b": false }, { "b": false }]);

        // filter, not expression
        var data = [ { "a": "a", "d": "e" }, { "a": "b", "d": "f" }, { "a": "d", "d": "f" } ];
        var result = JSONPath.query("$[?!(@.a=='b')]", data);
        Test.assertEqualsUnordered(result, [{ "a": "a", "d": "e" }, { "a": "d", "d": "f" }]);

        // filter, equals null, absent from data
        var data = [ { "d": "e" }, { "a": "c", "d": "f" } ];
        var result = JSONPath.query('$[?@.a==null]', data);
        Test.assertEqualsUnordered(result, []);

        // filter, not-equals null, absent from data
        var data = [ { "d": "e" }, { "a": "c", "d": "f" } ];
        var result = JSONPath.query('$[?@.a!=null]', data);
        Test.assertEqualsUnordered(result, [{ "d": "e" }, { "a": "c", "d": "f" }]);

        // filter, not exists
        var data = [ { "a": "a", "d": "e" }, { "d": "f" }, { "a": "d", "d": "f" } ];
        var result = JSONPath.query('$[?!@.a]', data);
        Test.assertEqualsUnordered(result, [{ "d": "f" }]);

        // filter, not exists, data null
        var data = [ { "a": null, "d": "e" }, { "d": "f" }, { "a": "d", "d": "f" } ];
        var result = JSONPath.query('$[?!@.a]', data);
        Test.assertEqualsUnordered(result, [{ "d": "f" }]);

        // filter, non-singular existence, negated
        var data:Array<Dynamic> = [ 1, [], [ 2 ], {}, { "a": 3 } ];
        var result = JSONPath.query('$[?!@.*]', data);
        Test.assertEqualsUnordered(result, [1, [], {}]);

        // filter, name segment on array, selects nothing
        var data = [ [ 5, 6 ] ];
        var result = JSONPath.query("$[?@['0'] == 5]", data);
        Test.assertEqualsUnordered(result, []);

        // filter, equals number, exponent
        var data:Array<Dynamic> = [ { "a": 100, "d": "e" }, { "a": 100.1, "d": "f" }, { "a": "100", "d": "g" } ];
        var result = JSONPath.query("$[?@.a==1e2]", data);
        Test.assertEqualsUnordered(result, [{ "a": 100, "d": "e" }]);

        // filter, equals number, positive exponent
        var data:Array<Dynamic> = [ { "a": 100, "d": "e" }, { "a": 100.1, "d": "f" }, { "a": "100", "d": "g" } ];
        var result = JSONPath.query("$[?@.a==1e+2]", data);
        Test.assertEqualsUnordered(result, [{ "a": 100, "d": "e" }]);

        // filter, equals number, negative exponent
        var data:Array<Dynamic> = [ { "a": 0.01, "d": "e" }, { "a": 0.02, "d": "f" }, { "a": "0.01", "d": "g" } ];
        var result = JSONPath.query("$[?@.a==1e-2]", data);
        Test.assertEqualsUnordered(result, [{ "a": 0.01, "d": "e" }]);

        // filter, equals number, decimal fraction, exponent
        var data:Array<Dynamic> = [ { "a": 110, "d": "e" }, { "a": 110.1, "d": "f" }, { "a": "110", "d": "g" } ];
        var result = JSONPath.query("$[?@.a==1.1e2]", data);
        Test.assertEqualsUnordered(result, [{ "a": 110, "d": "e" }]);

        // filter, equals, empty node list and special nothing
        var data:Array<Dynamic> = [ { "a": 1 }, { "b": 2 }, { "c": 3 } ];
        var result = JSONPath.query("$[?@.a == length(@.b)]", data);
        Test.assertEqualsUnordered(result, [ { "b": 2 }, { "c": 3 } ]);

        // name selector, double quotes, escaped ☺, lower case hex
        // TODO: Haxe does not handle non-ASCII characters in keys
        /*
        var data = { "☺": "A" };
        var result = JSONPath.query("$[\"\\u263a\"]", data);
        Test.assertEqualsUnordered(result, ["A"]);
        */

        // slice selector, excessively large step
        var data = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ];
        var result = JSONPath.query("$[1:10:113667776004]", data);
        Test.assertEqualsUnordered(result, [ 1 ]);

        // functions, count, count function
        var data:Array<Dynamic> = [ { "a": [ 1, 2, 3 ] }, { "a": [ 1 ], "d": "f" }, { "a": 1, "d": "f" } ];
        var result = JSONPath.query("$[?count(@..*)>2]", data);
        Test.assertEqualsUnordered(result, [ { "a": [ 1, 2, 3 ] }, { "a": [ 1 ], "d": "f" } ]);

        // filter, equals, special nothing
        var data1:Array<Dynamic> = [ { "a": "ab" }, { "c": "d" }, { "a": null } ];
        var data = { "c": "cd", "values": data1 };
        var result = JSONPath.query("$.values[?length(@.a) == value($..c)]", data);
        Test.assertEqualsUnordered(result, [ { "c": "d" }, { "a": null } ]);

        // whitespace, slice, space between start and colon
        var data = [1, 2, 3, 4, 5, 6];
        var result = JSONPath.query("$[1 :5:2]", data);
        Test.assertEqualsUnordered(result, [ 2, 4 ]);

        // whitespace, operators, space between logical not and test expression
        var data = [ { "a": "a", "d": "e" }, { "d": "f" }, { "a": "d", "d": "f" } ];
        var result = JSONPath.query("$[?! @.a]", data);
        Test.assertEqualsUnordered(result, [ { "d": "f" } ]);

        // functions, count, single-node arg
        var data:Array<Dynamic> = [ { "a": [ 1, 2, 3 ] }, { "a": [ 1 ], "d": "f" }, { "a": 1, "d": "f" } ];
        var result = JSONPath.query("$[?count(@.a)>1]", data);
        Test.assertEqualsUnordered(result, [ ]);

        // functions, count, multiple-selector arg
        var data:Array<Dynamic> = [ { "a": [ 1, 2, 3 ] }, { "a": [ 1 ], "d": "f" }, { "a": 1, "d": "f" } ];
        var result = JSONPath.query("$[?count(@['a','d'])>1]", data);
        Test.assertEqualsUnordered(result, [ { "a": [ 1 ], "d": "f" }, { "a": 1, "d": "f" } ]);

        // functions, length, number arg
        var data = [ { "d": "f" } ];
        var result = JSONPath.query("$[?length(1)>=2]", data);
        Test.assertEqualsUnordered(result, [ ]);

        // functions, length, arg is a function expression
        var data = { "c": "cd", "values": [ { "a": "ab" }, { "a": "d" } ] };
        var result = JSONPath.query("$.values[?length(@.a)==length(value($..c))]", data);
        Test.assertEqualsUnordered(result, [ { "a": "ab" } ]);
            
        // whitespace, functions, returns in an absolute singular selector
        var data = [ { "a": "foo" }, {} ];
        var result = JSONPath.query("$..[?length(@)==length($\r[0]\r.a)]", data);
        Test.assertEqualsUnordered(result, [ "foo" ]);

        // whitespace, operators, space between logical not and parenthesized expression
        var data = [ { "a": "a", "d": "e" }, { "a": "b", "d": "f" }, { "a": "d", "d": "f" } ];
        var result = JSONPath.query("$[?! (@.a=='b')]", data);
        Test.assertEqualsUnordered(result, [ { "a": "a", "d": "e" }, { "a": "d", "d": "f" } ]);

        // functions, length, true arg
        var data = [ { "d": "f" } ];
        var result = JSONPath.query("$[?length(true)>=2]", data);
        Test.assertEqualsUnordered(result, [ { "d": "f" } ]);

        // functions, match, found match
        var data = [ { "a": "ab" } ];
        var result = JSONPath.query("$[?match(@.a, 'a.*')]", data);
        Test.assertEqualsUnordered(result, [ { "a": "ab" } ]);

        // functions, match, regex from the document
        var data1:Array<Dynamic> = [ "abc", "bcd", "bab", "bba", "bbab", "b", true, [], {} ];
        var data = { "regex": "b.?b", "values": data1 };
        var result = JSONPath.query("$.values[?match(@, $.regex)]", data);
        Test.assertEqualsUnordered(result, [ "bab" ]);

        // functions, match, don't select match
        var data = [ { "a": "ab" } ];
        var result = JSONPath.query("$[?!match(@.a, 'a.*')]", data);
        Test.assertEqualsUnordered(result, [ ]);

        // functions, search, don't select match
        var data = [ { "a": "contains two matches" } ];
        var result = JSONPath.query("$[?!search(@.a, 'a.*')]", data);
        Test.assertEqualsUnordered(result, [ ]);
    }
}