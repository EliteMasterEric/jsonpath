package json.path;

import json.path.JSONPath.JSONPathParser;
import json.path.JSONPath.Element;
import json.path.PrimitiveLiteral;

class JSONPathParserTest
{
	public static function test():Void
	{
		testParse();

		trace('JSONPathParserTest: Done.');
	}

	public static function testParse():Void
	{
		var result = new JSONPathParser().parse('$');
		Test.assertEquals(result, Element.JSONPathQuery([]));

		var result = new JSONPathParser().parse('$.a');
		Test.assertEquals(result, Element.JSONPathQuery([Element.ChildSegment([Element.NameSelector('a')])]));

		var result = new JSONPathParser().parse('$.a[3, 5]');
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('a')]),
			Element.ChildSegment([Element.IndexSelector(3), Element.IndexSelector(5)])
		]));

		var result = new JSONPathParser().parse('$.a.b');
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('a')]),
			Element.ChildSegment([Element.NameSelector('b')])
		]));

		// From 2.3.1.3

		var result = new JSONPathParser().parse("$.o['j j']");
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('o')]),
			Element.ChildSegment([Element.NameSelector('j j')])
		]));

		var result = new JSONPathParser().parse("$.o['j j']['k k']");
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('o')]),
			Element.ChildSegment([Element.NameSelector('j j')]),
			Element.ChildSegment([Element.NameSelector('k k')])
		]));

		var result = new JSONPathParser().parse("$[\"'\"]['@']");
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector("'")]),
			Element.ChildSegment([Element.NameSelector('@')])
		]));

		// From 2.3.2.3

		var result = new JSONPathParser().parse("$[*]");
		Test.assertEquals(result, Element.JSONPathQuery([Element.ChildSegment([Element.WildcardSelector])]));

		var result = new JSONPathParser().parse("$.*");
		Test.assertEquals(result, Element.JSONPathQuery([Element.ChildSegment([Element.WildcardSelector])]));

		var result = new JSONPathParser().parse("$.o[*]");
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('o')]),
			Element.ChildSegment([Element.WildcardSelector])
		]));

		var result = new JSONPathParser().parse("$.o[*, *]");
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('o')]),
			Element.ChildSegment([Element.WildcardSelector, Element.WildcardSelector])
		]));

		var result = new JSONPathParser().parse("$.a[*]");
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('a')]),
			Element.ChildSegment([Element.WildcardSelector])
		]));

		// From 2.3.3.3

		var result = new JSONPathParser().parse("$[2]");
		Test.assertEquals(result, Element.JSONPathQuery([Element.ChildSegment([Element.IndexSelector(2)])]));

		var result = new JSONPathParser().parse("$[2, 3]");
		Test.assertEquals(result, Element.JSONPathQuery([Element.ChildSegment([Element.IndexSelector(2), Element.IndexSelector(3)])]));

		var result = new JSONPathParser().parse("$[-2]");
		Test.assertEquals(result, Element.JSONPathQuery([Element.ChildSegment([Element.IndexSelector(-2)])]));

		// From 2.3.4.3

		var result = new JSONPathParser().parse("$[1:3]");
		Test.assertEquals(result, Element.JSONPathQuery([Element.ChildSegment([Element.ArraySliceSelector(1, 3, null)])]));

		var result = new JSONPathParser().parse("$[5:]");
		Test.assertEquals(result, Element.JSONPathQuery([Element.ChildSegment([Element.ArraySliceSelector(5, null, null)])]));

		var result = new JSONPathParser().parse("$[1:5:2]");
		Test.assertEquals(result, Element.JSONPathQuery([Element.ChildSegment([Element.ArraySliceSelector(1, 5, 2)])]));

		var result = new JSONPathParser().parse("$[5:1:-2]");
		Test.assertEquals(result, Element.JSONPathQuery([Element.ChildSegment([Element.ArraySliceSelector(5, 1, -2)])]));

		var result = new JSONPathParser().parse("$[::-1]");
		Test.assertEquals(result, Element.JSONPathQuery([Element.ChildSegment([Element.ArraySliceSelector(null, null, -1)])]));

		// From 2.3.5.3

		var result = new JSONPathParser().parse("$.a[?@.b == 'kilo']");
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('a')]),
			Element.ChildSegment([
				Element.FilterSelector(Element.LogicalOrExpr([
					Element.LogicalComparisionExpr(Element.FilterQuery(Element.RelativeQuery([Element.ChildSegment([Element.NameSelector('b')])])), '==',
						Element.PrimitiveLiteralExpr(StringLiteral('kilo')))
				]))
			])
		]));

		var result = new JSONPathParser().parse("$.a[?(@.b == 'kilo')]");
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('a')]),
			Element.ChildSegment([
				Element.FilterSelector(Element.LogicalOrExpr([
					Element.LogicalComparisionExpr(Element.FilterQuery(Element.RelativeQuery([Element.ChildSegment([Element.NameSelector('b')])])), '==',
						Element.PrimitiveLiteralExpr(StringLiteral('kilo')))
				]))
			])
		]));

		var result = new JSONPathParser().parse("$.a[?@>3.5]");
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('a')]),
			Element.ChildSegment([
				Element.FilterSelector(Element.LogicalOrExpr([
					Element.LogicalComparisionExpr(Element.FilterQuery(Element.RelativeQuery([])), '>', Element.PrimitiveLiteralExpr(NumberLiteral(3.5)))
				]))
			])
		]));

		var result = new JSONPathParser().parse("$.a[?@.b]");
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('a')]),
			Element.ChildSegment([
				Element.FilterSelector(LogicalOrExpr([
					LogicalTestQueryExpr(Element.FilterQuery(Element.RelativeQuery([Element.ChildSegment([Element.NameSelector('b')])])))
				]))
			])
		]));

		var result = new JSONPathParser().parse("$[?@.*]");
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([
				Element.FilterSelector(Element.LogicalOrExpr([
					Element.LogicalTestQueryExpr(Element.FilterQuery(Element.RelativeQuery([Element.ChildSegment([Element.WildcardSelector])])))
				]))
			])
		]));

		var result = new JSONPathParser().parse("$[?@[?@.b]]");
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([
				Element.FilterSelector(Element.LogicalOrExpr([
					Element.LogicalTestQueryExpr(Element.FilterQuery(Element.RelativeQuery([
						Element.ChildSegment([
							Element.FilterSelector(Element.LogicalOrExpr([
								Element.LogicalTestQueryExpr(Element.FilterQuery(Element.RelativeQuery([Element.ChildSegment([Element.NameSelector('b')])])))
							]))
						])
					])))
				]))
			])
		]));

		var result = new JSONPathParser().parse("$.o[?@<3, ?@<3]");
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('o')]),
			Element.ChildSegment([
				Element.FilterSelector(Element.LogicalOrExpr([
					Element.LogicalComparisionExpr(Element.FilterQuery(Element.RelativeQuery([])), '<', Element.PrimitiveLiteralExpr(IntegerLiteral(3))),
				])),
				Element.FilterSelector(Element.LogicalOrExpr([
					Element.LogicalComparisionExpr(Element.FilterQuery(Element.RelativeQuery([])), '<', Element.PrimitiveLiteralExpr(IntegerLiteral(3))),
				]))
			])
		]));

		var result = new JSONPathParser().parse('$.a[?@<2 || @.b == "k"]');
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('a')]),
			Element.ChildSegment([
				Element.FilterSelector(Element.LogicalOrExpr([
					Element.LogicalComparisionExpr(Element.FilterQuery(Element.RelativeQuery([])), '<', Element.PrimitiveLiteralExpr(IntegerLiteral(2))),
					Element.LogicalComparisionExpr(Element.FilterQuery(Element.RelativeQuery([Element.ChildSegment([Element.NameSelector('b')])])), '==',
						Element.PrimitiveLiteralExpr(StringLiteral('k')))
				]))
			])
		]));

		var result = new JSONPathParser().parse('$.a[?match(@.b, "[jk]")]');
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('a')]),
			Element.ChildSegment([
				Element.FilterSelector(Element.LogicalOrExpr([
					Element.LogicalTestQueryExpr(Element.FunctionExpressionElement('match', [
						Element.LogicalTestQueryExpr(Element.FilterQuery(Element.RelativeQuery([Element.ChildSegment([Element.NameSelector('b')])]))),
						Element.PrimitiveLiteralExpr(StringLiteral('[jk]'))
					]))
				]))
			])
		]));

		var result = new JSONPathParser().parse('$.a[?search(@.b, "[jk]")]');
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('a')]),
			Element.ChildSegment([
				Element.FilterSelector(Element.LogicalOrExpr([
					Element.LogicalTestQueryExpr(Element.FunctionExpressionElement('search', [
						Element.LogicalTestQueryExpr(Element.FilterQuery(Element.RelativeQuery([Element.ChildSegment([Element.NameSelector('b')])]))),
						Element.PrimitiveLiteralExpr(StringLiteral('[jk]'))
					]))
				]))
			])
		]));

		var result = new JSONPathParser().parse('$.o[?@>1 && @<4]');
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('o')]),
			Element.ChildSegment([
				Element.FilterSelector(Element.LogicalOrExpr([
					Element.LogicalAndExpr([
						Element.LogicalComparisionExpr(Element.FilterQuery(Element.RelativeQuery([])), '>', Element.PrimitiveLiteralExpr(IntegerLiteral(1))),
						Element.LogicalComparisionExpr(Element.FilterQuery(Element.RelativeQuery([])), '<', Element.PrimitiveLiteralExpr(IntegerLiteral(4)))
					])
				]))
			])
		]));

		var result = new JSONPathParser().parse('$.o[?@.u || @.x]');
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('o')]),
			Element.ChildSegment([
				Element.FilterSelector(Element.LogicalOrExpr([
					Element.LogicalTestQueryExpr(Element.FilterQuery(Element.RelativeQuery([Element.ChildSegment([Element.NameSelector('u')])]))),
					Element.LogicalTestQueryExpr(Element.FilterQuery(Element.RelativeQuery([Element.ChildSegment([Element.NameSelector('x')])])))
				]))
			])
		]));

		var result = new JSONPathParser().parse('$.a[?@.b == $.x]');
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('a')]),
			Element.ChildSegment([
				Element.FilterSelector(Element.LogicalOrExpr([
					Element.LogicalComparisionExpr(Element.FilterQuery(Element.RelativeQuery([Element.ChildSegment([Element.NameSelector('b')])])), '==',
						Element.FilterQuery(Element.JSONPathQuery([Element.ChildSegment([Element.NameSelector('x')])])))
				]))
			])
		]));

		// From 2.5.2.3

		var result = new JSONPathParser().parse('$..j');
		Test.assertEquals(result, Element.JSONPathQuery([Element.DescendantSegment([Element.NameSelector('j')])]));

		var result = new JSONPathParser().parse('$..[0]');
		Test.assertEquals(result, Element.JSONPathQuery([Element.DescendantSegment([Element.IndexSelector(0)])]));

		var result = new JSONPathParser().parse('$..[*]');
		Test.assertEquals(result, Element.JSONPathQuery([Element.DescendantSegment([Element.WildcardSelector])]));

		var result = new JSONPathParser().parse('$..*');
		Test.assertEquals(result, Element.JSONPathQuery([Element.DescendantSegment([Element.WildcardSelector])]));

		var result = new JSONPathParser().parse('$..o');
		Test.assertEquals(result, Element.JSONPathQuery([Element.DescendantSegment([Element.NameSelector('o')])]));

		var result = new JSONPathParser().parse('$.o..[*, *]');
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('o')]),
			Element.DescendantSegment([Element.WildcardSelector, Element.WildcardSelector])
		]));

		var result = new JSONPathParser().parse('$.a..[0, 1]');
		Test.assertEquals(result, Element.JSONPathQuery([
			Element.ChildSegment([Element.NameSelector('a')]),
			Element.DescendantSegment([Element.IndexSelector(0), Element.IndexSelector(1)])
		]));

		// Test bugs

		var result = new JSONPathParser().parse('$["*"]');
		trace(result);

		// var result = new JSONPathParser().parse('$."*"');
		// trace(result);

		var result = new JSONPathParser().parse('$[foo-bar, baz]');
		trace(result);
	}
}
