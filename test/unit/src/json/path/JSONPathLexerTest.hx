package json.path;

import json.path.JSONPath.JSONPathLexer;
import json.path.JSONPath.Token;

class JSONPathLexerTest
{
	public static function test():Void
	{
		testLexer();
		testLexerSummary();
		testLexerExamples();

		trace('JSONPathLexerTest: Done.');
	}

	public static function testLexer():Void
	{
		var result = new JSONPathLexer().tokenize('$');
		Test.assertEquals(result, [Token.Dollar]);

		var result = new JSONPathLexer().tokenize('$ ');
		Test.assertEquals(result, [Token.Dollar, Token.Whitespace]);

		var result = new JSONPathLexer().tokenize('$\t');
		Test.assertEquals(result, [Token.Dollar, Token.Whitespace]);

		var result = new JSONPathLexer().tokenize('\n');
		Test.assertEquals(result, [Token.Whitespace]);

		var result = new JSONPathLexer().tokenize('"Hello"');
		Test.assertEquals(result, [Token.StringLiteral('Hello')]);

		var result = new JSONPathLexer().tokenize('\'Goodbye\'');
		Test.assertEquals(result, [Token.StringLiteral('Goodbye')]);

		var result = new JSONPathLexer().tokenize('"Hello World"');
		Test.assertEquals(result, [Token.StringLiteral('Hello World')]);

		var result = new JSONPathLexer().tokenize('"te\\nst"');
		Test.assertEquals(result, [Token.StringLiteral('te\nst')]);

		var result = new JSONPathLexer().tokenize('"\'"');
		Test.assertEquals(result, [Token.StringLiteral("'")]);

		var result = new JSONPathLexer().tokenize("'\"'");
		Test.assertEquals(result, [Token.StringLiteral('"')]);

		var result = new JSONPathLexer().tokenize("'\\\\'");
		Test.assertEquals(result, [Token.StringLiteral('\\')]);

		// TODO: Figure out what's up with Haxe's string representation.
		// var result = new JSONPathLexer().tokenize('"\\u263A"');
		// Test.assertEquals(result, [Token.StringLiteral("☺")]);

		var result = new JSONPathLexer().tokenize('"\\u40"');
		Test.assertEquals(result, [Token.StringLiteral('@')]);

		var result = new JSONPathLexer().tokenize('*');
		Test.assertEquals(result, [Token.Asterisk]);

		var result = new JSONPathLexer().tokenize('$*');
		Test.assertEquals(result, [Token.Dollar, Token.Asterisk]);

		var result = new JSONPathLexer().tokenize('17');
		Test.assertEquals(result, [Token.IntegerLiteral(17)]);

		var result = new JSONPathLexer().tokenize('$  ');
		Test.assertEquals(result, [Token.Dollar, Whitespace]);

		var result = new JSONPathLexer().tokenize('$   ');
		Test.assertEquals(result, [Token.Dollar, Whitespace]);

		var result = new JSONPathLexer().tokenize('$17');
		Test.assertEquals(result, [Token.Dollar, Token.IntegerLiteral(17)]);

		var result = new JSONPathLexer().tokenize('$17.6');
		Test.assertEquals(result, [Token.Dollar, Token.NumberLiteral(17.6)]);

		var result = new JSONPathLexer().tokenize('$ 17');
		Test.assertEquals(result, [Token.Dollar, Whitespace, Token.IntegerLiteral(17)]);

		var result = new JSONPathLexer().tokenize('$  17  ');
		Test.assertEquals(result, [Token.Dollar, Whitespace, Token.IntegerLiteral(17), Whitespace]);

		var result = new JSONPathLexer().tokenize('$-34');
		Test.assertEquals(result, [Token.Dollar, Token.IntegerLiteral(-34)]);

		var result = new JSONPathLexer().tokenize('$:');
		Test.assertEquals(result, [Token.Dollar, Token.Colon]);

		var result = new JSONPathLexer().tokenize('$::');
		Test.assertEquals(result, [Token.Dollar, Token.Colon, Token.Colon]);

		var result = new JSONPathLexer().tokenize('$(::)');
		Test.assertEquals(result, [Token.Dollar, Token.Parens([Token.Colon, Token.Colon])]);

		var result = new JSONPathLexer().tokenize("${::}");
		Test.assertEquals(result, [Token.Dollar, Token.Braces([Token.Colon, Token.Colon])]);

		var result = new JSONPathLexer().tokenize("$[::]");
		Test.assertEquals(result, [Token.Dollar, Token.Brackets([Token.Colon, Token.Colon])]);

		var result = new JSONPathLexer().tokenize('$((1))');
		Test.assertEquals(result, [Token.Dollar, Token.Parens([Token.Parens([Token.IntegerLiteral(1)])])]);

		var result = new JSONPathLexer().tokenize('$((1) (2))');
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Parens([
				Token.Parens([Token.IntegerLiteral(1)]),
				Whitespace,
				Token.Parens([Token.IntegerLiteral(2)])
			])
		]);

		var result = new JSONPathLexer().tokenize('$==!=><>=<=');
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Comparison('=='),
			Token.Comparison('!='),
			Token.Comparison('>'),
			Token.Comparison('<'),
			Token.Comparison('>='),
			Token.Comparison('<=')
		]);

		var result = new JSONPathLexer().tokenize("$[::-1]");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Brackets([Token.Colon, Token.Colon, Token.IntegerLiteral(-1)])
		]);
	}

	public static function testLexerSummary():Void
	{
		// From 1.4.4 Summary

		var result = new JSONPathLexer().tokenize('$');
		Test.assertEquals(result, [Token.Dollar]);

		var result = new JSONPathLexer().tokenize('@');
		Test.assertEquals(result, [Token.At]);

		var result = new JSONPathLexer().tokenize('[1]');
		Test.assertEquals(result, [Token.Brackets([Token.IntegerLiteral(1)])]);

		var result = new JSONPathLexer().tokenize('.name');
		Test.assertEquals(result, [Token.Dot, Token.MemberName('name')]);

		var result = new JSONPathLexer().tokenize('.*');
		Test.assertEquals(result, [Token.Dot, Token.Asterisk]);

		var result = new JSONPathLexer().tokenize('..[1]');
		Test.assertEquals(result, [Token.DoubleDot, Token.Brackets([Token.IntegerLiteral(1)])]);

		var result = new JSONPathLexer().tokenize('..name');
		Test.assertEquals(result, [Token.DoubleDot, Token.MemberName('name')]);

		var result = new JSONPathLexer().tokenize('..*');
		Test.assertEquals(result, [Token.DoubleDot, Token.Asterisk]);

		var result = new JSONPathLexer().tokenize("['name']");
		Test.assertEquals(result, [Token.Brackets([Token.StringLiteral('name')])]);

		var result = new JSONPathLexer().tokenize('*');
		Test.assertEquals(result, [Token.Asterisk]);

		var result = new JSONPathLexer().tokenize('$.a.b');
		Test.assertEquals(result, [Token.Dollar, Token.Dot, Token.MemberName('a'), Token.Dot, Token.MemberName('b')]);

		var result = new JSONPathLexer().tokenize('3');
		Test.assertEquals(result, [Token.IntegerLiteral(3)]);

		var result = new JSONPathLexer().tokenize('0:100:5');
		Test.assertEquals(result, [
			Token.IntegerLiteral(0),
			Token.Colon,
			Token.IntegerLiteral(100),
			Token.Colon,
			Token.IntegerLiteral(5)
		]);

		var result = new JSONPathLexer().tokenize('?$.absent1 == $.absent2');
		Test.assertEquals(result, [
			Token.Question, Token.Dollar, Token.Dot, Token.MemberName('absent1'), Token.Whitespace, Token.Comparison('=='), Token.Whitespace, Token.Dollar,
			Token.Dot, Token.MemberName('absent2')]);
	}

	public static function testLexerExamples():Void
	{
		// From 1.5. Figure 1

		var result = new JSONPathLexer().tokenize("$.store.book[*].author");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Dot,
			Token.MemberName('store'),
			Token.Dot,
			Token.MemberName('book'),
			Token.Brackets([Token.Asterisk]),
			Token.Dot,
			Token.MemberName('author')
		]);

		var result = new JSONPathLexer().tokenize("$..author");
		Test.assertEquals(result, [Token.Dollar, Token.DoubleDot, Token.MemberName('author')]);

		var result = new JSONPathLexer().tokenize("$.store.*");
		Test.assertEquals(result, [Token.Dollar, Token.Dot, Token.MemberName('store'), Token.Dot, Token.Asterisk]);

		var result = new JSONPathLexer().tokenize("$.store..price");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Dot,
			Token.MemberName('store'),
			Token.DoubleDot,
			Token.MemberName('price')
		]);

		var result = new JSONPathLexer().tokenize("$..book[2]");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.DoubleDot,
			Token.MemberName('book'),
			Token.Brackets([Token.IntegerLiteral(2)])
		]);

		var result = new JSONPathLexer().tokenize("$..book[2].author");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.DoubleDot,
			Token.MemberName('book'),
			Token.Brackets([Token.IntegerLiteral(2)]),
			Token.Dot,
			Token.MemberName('author')
		]);

		var result = new JSONPathLexer().tokenize("$..book[2].publisher");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.DoubleDot,
			Token.MemberName('book'),
			Token.Brackets([Token.IntegerLiteral(2)]),
			Token.Dot,
			Token.MemberName('publisher')
		]);

		var result = new JSONPathLexer().tokenize("$..book[-1]");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.DoubleDot,
			Token.MemberName('book'),
			Token.Brackets([Token.IntegerLiteral(-1)])
		]);

		var result = new JSONPathLexer().tokenize("$..book[0,1]");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.DoubleDot,
			Token.MemberName('book'),
			Token.Brackets([Token.IntegerLiteral(0), Token.Comma, Token.IntegerLiteral(1)])
		]);

		var result = new JSONPathLexer().tokenize("$..book[:2]");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.DoubleDot,
			Token.MemberName('book'),
			Token.Brackets([Token.Colon, Token.IntegerLiteral(2)])
		]);

		var result = new JSONPathLexer().tokenize("$..book[?@.isbn]");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.DoubleDot,
			Token.MemberName('book'),
			Token.Brackets([Token.Question, Token.At, Token.Dot, Token.MemberName('isbn')])
		]);

		var result = new JSONPathLexer().tokenize("$..book[?@.price<10]");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.DoubleDot,
			Token.MemberName('book'),
			Token.Brackets([
				Token.Question,
				Token.At,
				Token.Dot,
				Token.MemberName('price'),
				Token.Comparison('<'),
				Token.IntegerLiteral(10)
			])
		]);

		var result = new JSONPathLexer().tokenize("$..*");
		Test.assertEquals(result, [Token.Dollar, Token.DoubleDot, Token.Asterisk]);

		// From 2.3.5.3.

		var result = new JSONPathLexer().tokenize("$.a[?@.b == 'kilo']");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Dot,
			Token.MemberName('a'),
			Token.Brackets([
				Token.Question,
				Token.At,
				Token.Dot,
				Token.MemberName('b'),
				Token.Whitespace,
				Token.Comparison('=='),
				Token.Whitespace,
				Token.StringLiteral('kilo')
			])
		]);

		var result = new JSONPathLexer().tokenize("$.a[?(@.b == 'kilo')]");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Dot,
			Token.MemberName('a'),
			Token.Brackets([
				Token.Question,
				Token.Parens([
					Token.At,
					Token.Dot,
					Token.MemberName('b'),
					Token.Whitespace,
					Token.Comparison('=='),
					Token.Whitespace,
					Token.StringLiteral('kilo')
				])
			])
		]);

		var result = new JSONPathLexer().tokenize("$.a[?@>3.5]");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Dot,
			Token.MemberName('a'),
			Token.Brackets([Token.Question, Token.At, Token.Comparison('>'), Token.NumberLiteral(3.5)])
		]);

		var result = new JSONPathLexer().tokenize("$.a[?@.b]");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Dot,
			Token.MemberName('a'),
			Token.Brackets([Token.Question, Token.At, Token.Dot, Token.MemberName('b')])
		]);

		var result = new JSONPathLexer().tokenize("$[?@.*]");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Brackets([Token.Question, Token.At, Token.Dot, Token.Asterisk])
		]);

		var result = new JSONPathLexer().tokenize("$[?@[?@.b]]");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Brackets([
				Token.Question,
				Token.At,
				Token.Brackets([Token.Question, Token.At, Token.Dot, Token.MemberName('b')])
			])
		]);

		var result = new JSONPathLexer().tokenize("$.o[?@<3, ?@<3]");
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Dot,
			Token.MemberName('o'),
			Token.Brackets([
				Token.Question, Token.At, Token.Comparison('<'), Token.IntegerLiteral(3), Token.Comma, Token.Whitespace, Token.Question, Token.At,
				Token.Comparison('<'), Token.IntegerLiteral(3)])
		]);

		var result = new JSONPathLexer().tokenize('$.a[?@<2 || @.b == "k"]');
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Dot,
			Token.MemberName('a'),
			Token.Brackets([
				Token.Question, Token.At, Token.Comparison('<'), Token.IntegerLiteral(2), Token.Whitespace, Token.LogicalOr, Token.Whitespace, Token.At,
				Token.Dot, Token.MemberName('b'), Token.Whitespace, Token.Comparison('=='), Token.Whitespace, Token.StringLiteral('k')])
		]);

		var result = new JSONPathLexer().tokenize('$.a[?match(@.b, "[jk]")]');
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Dot,
			Token.MemberName('a'),
			Token.Brackets([
				Token.Question,
				Token.MemberName('match'),
				Token.Parens([
					Token.At,
					Token.Dot,
					Token.MemberName('b'),
					Token.Comma,
					Token.Whitespace,
					Token.StringLiteral('[jk]')
				])
			])
		]);

		var result = new JSONPathLexer().tokenize('$.a[?search(@.b, "[jk]")]');
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Dot,
			Token.MemberName('a'),
			Token.Brackets([
				Token.Question,
				Token.MemberName('search'),
				Token.Parens([
					Token.At,
					Token.Dot,
					Token.MemberName('b'),
					Token.Comma,
					Token.Whitespace,
					Token.StringLiteral('[jk]')
				])
			])
		]);

		var result = new JSONPathLexer().tokenize('$.o[?@>1 && @<4]');
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Dot,
			Token.MemberName('o'),
			Token.Brackets([
				Token.Question, Token.At, Token.Comparison('>'), Token.IntegerLiteral(1), Token.Whitespace, Token.LogicalAnd, Token.Whitespace, Token.At,
				Token.Comparison('<'), Token.IntegerLiteral(4)])
		]);

		var result = new JSONPathLexer().tokenize('$.o[?@.u || @.x]');
		Test.assertEquals(result, [
			Token.Dollar,
			Token.Dot,
			Token.MemberName('o'),
			Token.Brackets([
				Token.Question, Token.At, Token.Dot, Token.MemberName('u'), Token.Whitespace, Token.LogicalOr, Token.Whitespace, Token.At, Token.Dot,
				Token.MemberName('x')])
		]);
	}

	public static function testLexerError():Void
	{
		Test.assertError(() ->
		{
			var result = new JSONPathLexer().tokenize('~');
		}, 'Unexpected character at pos 1: ~');
	}
}
