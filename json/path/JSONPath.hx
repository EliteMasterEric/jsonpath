package json.path;

import json.JSONData;
import json.util.SliceUtil;
import json.util.ArrayUtil;
import json.path.PrimitiveLiteral;
import json.path.FunctionExpression;

using StringTools;

/**
 * A JSONPath is a query consisting of a root identifier followed by a series of segments (with optional blank space between).
 * Each segment takes the result of the previous root identifier (or segment) and provides input to the next segment, in the form of a nodelist.
 * A valid query is executed against a value and produces a node list.
 */
class JSONPath
{
	/**
	 * Performs the provided JSONPath query on the query argument,
	 * and provides the query result as a list of JSON values that were located.
	 * @param path 
	 * @param value 
	 * @return Array<String>
	 */
	public static function query(path:String, value:JSONData):Array<JSONData>
	{
		var element = new JSONPathParser().parse(path);

		var nodelist = queryPaths_Element(element, value);

		return mapNodelistValues(nodelist);
	}

	/**
	 * Performs the provided JSONPath query on the query argument,
	 * and provides the query result as a list of normalized paths into the query argument.
	 * @param path 
	 * @param value 
	 * @return Array<String>
	 */
	public static function queryPaths(path:String, value:JSONData):Array<String>
	{
		var element = new JSONPathParser().parse(path);

		switch (element)
		{
			case Element.JSONPathQuery(segments):
				var nodelist = queryPaths_Element(element, value);
				return mapNodelistPaths(nodelist);
			default:
				throw pathError_noRootIdentifier(element);
		}
	}

	static function mapNodelistPaths(nodelist:Array<JSONNode>):Array<String>
	{
		return nodelist.map(function(node:JSONNode):String
		{
			return node.path;
		});
	}

	static function mapNodelistValues(nodelist:Array<JSONNode>):Array<JSONData>
	{
		return nodelist.map(function(node:JSONNode):JSONData
		{
			return node.value;
		});
	}

	static function queryPaths_Element(element:Element, rootValue:JSONData):Array<JSONNode>
	{
		switch (element)
		{
			case Element.JSONPathQuery(segments):
				var nodeList:Array<JSONNode> = [
					{
						path: '$',
						value: rootValue
					}
				];

				for (segment in segments)
				{
					switch (segment)
					{
						case ChildSegment(selectors):
							nodeList = queryPaths_ChildSegment(selectors, nodeList, rootValue);
						case DescendantSegment(selectors):
							nodeList = queryPaths_DescendantSegment(selectors, nodeList, rootValue);
						default:
							throw pathError_unexpectedElement(segment);
					}
				}

				return nodeList;
			case Element.RelativeQuery(segments):
				var nodeList:Array<JSONNode> = [
					{
						path: '@',
						value: rootValue
					}
				];

				for (segment in segments)
				{
					switch (segment)
					{
						case ChildSegment(selectors):
							nodeList = queryPaths_ChildSegment(selectors, nodeList, rootValue);
						case DescendantSegment(selectors):
							nodeList = queryPaths_DescendantSegment(selectors, nodeList, rootValue);
						default:
							throw pathError_unexpectedElement(segment);
					}
				}

				return nodeList;
			default:
				throw pathError_noRootIdentifier(element);
		}
	}

	static function queryPaths_ElementQuery(element:Element, targetValue:JSONData, rootValue:JSONData):Array<JSONNode>
	{
		switch (element)
		{
			case Element.JSONPathQuery(_):
				return queryPaths_Element(element, rootValue);
			case Element.RelativeQuery(_):
				return queryPaths_Element(element, targetValue);
			default:
				throw 'Expected relative or absolute query, got ${element}';
		}
	}

	static function queryPaths_ChildSegment(selectors:Array<Element>, nodeList:Array<JSONNode>, rootValue:JSONData):Array<JSONNode>
	{
		var result:Array<JSONNode> = [];

		for (selector in selectors)
		{
			switch (selector)
			{
				case NameSelector(name):
					for (node in nodeList)
					{
						if (node.value == null)
							continue;
						if (node.value.isArray())
							continue;
						if (!node.value.exists(name))
							continue;

						var newPath = node.path + "['" + name + "']";
						result.push({
							path: newPath,
							value: node.value.get(name)
						});
					}
				case IndexSelector(index):
					for (node in nodeList)
					{
						if (!node.value.isArray())
							continue;
						if (index < 0)
							index = node.value.length() + index;
						// Index out of bounds, provide no result.
						if (index < 0 || index >= node.value.length())
							continue;

						if (!node.value.exists('$index'))
							continue;
						var newPath = node.path + "[" + index + "]";
						result.push({
							path: newPath,
							value: node.value.get('$index')
						});
					}
				case WildcardSelector:
					for (node in nodeList)
					{
						if (node.value.isPrimitive())
							continue;

						var isArray = node.value.isArray();
						var keys = node.value.keys();

						for (key in keys)
						{
							var newPath = node.path + (isArray ? "[" + key + "]" : "['" + key + "']");
							result.push({
								path: newPath,
								value: node.value.get(key)
							});
						}
					}
				case ArraySliceSelector(start, end, step):
					for (node in nodeList)
					{
						if (!node.value.isArray())
							continue;

						var indices = SliceUtil.getSliceIndices(node.value.length(), start, end, step);

						for (index in indices)
						{
							var newPath = node.path + "[" + index + "]";
							result.push({
								path: newPath,
								value: node.value.get('$index')
							});
						}
					}
				case FilterSelector(filter):
					for (node in nodeList)
					{
						var results = queryPaths_ChildFilterSelector(filter, node, rootValue);

						result = result.concat(results);
					}
				default:
					throw pathError_unexpectedElement(selector);
			}
		}

		return result;
	}

	static function queryPaths_ChildFilterSelector(filter:Element, targetNode:JSONNode, rootValue:JSONData):Array<JSONNode>
	{
		// Calculate a list of all the child elements of the target node that match the filter.
		if (filter == null || targetNode.value == null || targetNode.value.isPrimitive())
			return [];

		var result = [];

		switch (filter)
		{
			case LogicalOrExpr(values):
				for (value in values)
				{
					var subResult = queryPaths_ChildFilterSelector(value, targetNode, rootValue);
					// TODO: Does this break queries with duplicate values in?
					if (result.length == 0)
					{
						result = subResult;
					}
					else
					{
						result = result.concat(ArrayUtil.subtract(subResult, result));
					}
				}
			case LogicalAndExpr(values):
				var hasFirstResult = false;
				for (value in values)
				{
					var subResult = queryPaths_ChildFilterSelector(value, targetNode, rootValue);
					if (!hasFirstResult)
					{
						hasFirstResult = true;
						result = subResult;
					}
					else
					{
						result = ArrayUtil.intersect(result, subResult);
					}
				}
			case LogicalNotExpr(value):
				var keys = targetNode.value.keys();
				var isArray = targetNode.value.isArray();
				var subResultAll:Array<JSONNode> = [];
				for (key in keys)
				{
					var childValue = targetNode.value.get(key);
					var childPath = targetNode.path + (isArray ? "[" + key + "]" : "['" + key + "']");
					var childNode = {
						path: childPath,
						value: childValue
					};
					subResultAll.push(childNode);
				}

				var subResult = queryPaths_ChildFilterSelector(value, targetNode, rootValue);

				result = ArrayUtil.subtract(subResultAll, subResult);
			case LogicalTestQueryExpr(value):
				switch (value)
				{
					case FilterQuery(value):
						// Check for existance of the query result.
						var queryResult = queryPaths_TestFilterQuery(value, targetNode, rootValue);
						result = result.concat(queryResult);
					case FunctionExpressionElement(name, args):
						var queryResult = queryPaths_TestFunctionExpression(name, args, targetNode, rootValue);
						result = result.concat(queryResult);
					default:
						throw pathError_unexpectedElement(filter);
				}
			case LogicalComparisionExpr(value1, op, value2):
				var subResult = queryPaths_LogicalComparision(value1, op, value2, targetNode, rootValue);
				result = result.concat(subResult);
			default:
				throw pathError_unexpectedElement(filter);
		}

		return result;
	}

	static function queryPaths_LogicalComparision(left:Element, op:String, right:Element, targetNode:JSONNode, rootValue:JSONData):Array<JSONNode>
	{
		var keys = targetNode.value.keys();
		var isArray = targetNode.value.isArray();

		var results:Array<JSONNode> = [];

		for (key in keys)
		{
			var childValue = targetNode.value.get(key);
			var childPath = targetNode.path + (isArray ? "[" + key + "]" : "['" + key + "']");
			var childNode = {
				path: childPath,
				value: childValue
			};

			// Evaluate the left and right sides of the comparison to primitives, then compare them.
			var leftValue:PrimitiveLiteral = queryPaths_Comparable(left, childNode, rootValue);
			var rightValue:PrimitiveLiteral = queryPaths_Comparable(right, childNode, rootValue);
			var result:Bool = PrimitiveLiteralTools.compare(leftValue, op, rightValue);
			if (result)
			{
				results.push(childNode);
			}
		}

		return results;
	}

	/**
	 * Evaluate the expression and evaluate it to a literal.
	 * If the expression evaluates to a node, return a BoolLiteral for whether it exists.
	 * If the expression evaluates to a value, return a Literal for that value.
	 */
	static function queryPaths_Comparable(expression:Element, targetNode:JSONNode, rootValue:JSONData, ?asNodelist:Bool = false):PrimitiveLiteral
	{
		switch (expression)
		{
			case LogicalTestQueryExpr(element):
				return queryPaths_Comparable(element, targetNode, rootValue, asNodelist);
			case PrimitiveLiteralExpr(value):
				return value;
			case FunctionExpressionElement(name, arguments):
				return queryPaths_FunctionExpression_Value(name, arguments, targetNode, rootValue);
			case FilterQuery(value):
				var subResult = queryPaths_ValueFilterQuery(value, targetNode, rootValue);
				if (subResult.length > 1)
				{
					var result = subResult.map((node) -> PrimitiveLiteralTools.fromJSONData(node.value));
					return NodelistLiteral(result);
				}
				else if (subResult.length == 1)
				{
					if (subResult[0] == null)
					{
						return NothingLiteral;
					}
					else if (asNodelist)
					{
						return NodelistLiteral([PrimitiveLiteralTools.fromJSONData(subResult[0].value)]);
					}
					else
					{
						return PrimitiveLiteralTools.fromJSONData(subResult[0].value);
					}
				}
				else
				{
					return UndefinedLiteral;
				}
			default:
				throw pathError_unexpectedElement(expression);
		}
	}

	static function queryPaths_FunctionExpression_Value(name:String, arguments:Array<Element>, targetNode:JSONNode, rootValue:JSONData):PrimitiveLiteral
	{
		var parsedArgs:Array<PrimitiveLiteral> = [];
		for (arg in arguments)
		{
			parsedArgs.push(queryPaths_Comparable(arg, targetNode, rootValue, true));
		}

		if (!FunctionExpression.isValidFunctionExpression(name))
		{
			throw 'Unknown function: ${name}';
		}

		return FunctionExpression.evaluateFunction(name, parsedArgs);
	}

	/**
	 * Return each node which matches the subquery.
	 * For example, [@.b] returns each node which contains `b`
	 */
	static function queryPaths_TestFilterQuery(subquery:Element, targetNode:JSONNode, rootValue:JSONData):Array<JSONNode>
	{
		// Perform a filter query on the child elements of the target node.
		var keys = targetNode.value.keys();
		var isArray = targetNode.value.isArray();

		var results:Array<JSONNode> = [];
		for (key in keys)
		{
			var childValue = targetNode.value.get(key);
			var childPath = targetNode.path + (isArray ? "[" + key + "]" : "['" + key + "']");
			var childNode = {
				path: childPath,
				value: childValue
			};

			var subResult = queryPaths_ElementQuery(subquery, childNode.value, rootValue);
			if (subResult.length > 0)
			{
				results.push(childNode);
			}
		}

		return results;
	}

	/**
	 * Return each node for which the function evaluates to true.
	 */
	static function queryPaths_TestFunctionExpression(name:String, args:Array<Element>, targetNode:JSONNode, rootValue:JSONData):Array<JSONNode>
	{
		// Perform a filter query on the child elements of the target node.
		var keys = targetNode.value.keys();
		var isArray = targetNode.value.isArray();

		var results:Array<JSONNode> = [];
		for (key in keys)
		{
			var childValue = targetNode.value.get(key);
			var childPath = targetNode.path + (isArray ? "[" + key + "]" : "['" + key + "']");
			var childNode = {
				path: childPath,
				value: childValue
			};

			var subResult = queryPaths_FunctionExpression_Value(name, args, childNode, rootValue);
			switch (subResult)
			{
				case BooleanLiteral(value):
					if (value)
					{
						results.push(childNode);
					}
				default:
					// Do nothing
			}
		}

		return results;
	}

	/**
	 * Return each value for the subquery.
	 * For example, [@.b] returns each value of `b`
	 */
	static function queryPaths_ValueFilterQuery(subquery:Element, targetNode:JSONNode, rootValue:JSONData):Array<JSONNode>
	{
		// Perform a filter query on the child elements of the target node.
		var keys = targetNode.value.keys();
		var isArray = targetNode.value.isArray();

		var results:Array<JSONNode> = [];

		var subResult = queryPaths_ElementQuery(subquery, targetNode.value, rootValue);
		results = results.concat(subResult);

		return results;
	}

	static function queryPaths_DescendantSegment(selectors:Array<Element>, nodeList:Array<JSONNode>, rootValue:JSONData):Array<JSONNode>
	{
		var result:Array<JSONNode> = [];

		var descendantList = buildDescendantList(nodeList);
		var fullList = nodeList.concat(descendantList);

		for (selector in selectors)
		{
			switch (selector)
			{
				case NameSelector(name):
					for (node in fullList)
					{
						var newPath = node.path + "['" + name + "']";

						if (node.value.isArray())
							continue;
						var pathValue = node.value.get(name);
						if (pathValue == null)
							continue;

						result.push({
							path: newPath,
							value: pathValue
						});
					}
				case IndexSelector(index):
					for (node in fullList)
					{
						if (!node.value.isArray())
							continue;
						if (index < 0)
							index = node.value.length() + index;
						// Index out of bounds, provide no result.
						if (index < 0 || index >= node.value.length())
							continue;

						var newPath = node.path + "[" + index + "]";
						var pathValue = node.value.get('$index');
						if (pathValue == null)
							continue;
						result.push({
							path: newPath,
							value: node.value.get('$index')
						});
					}
				case WildcardSelector:
					for (node in fullList)
					{
						var isArray = node.value.isArray();

						var keys = node.value.keys();

						for (key in keys)
						{
							var newPath = node.path + (isArray ? "[" + key + "]" : "['" + key + "']");
							result.push({
								path: newPath,
								value: node.value.get(key)
							});
						}
					}
				case ArraySliceSelector(start, end, step):
					for (node in fullList)
					{
						if (!node.value.isArray())
							continue;
						var indices = SliceUtil.getSliceIndices(node.value.length(), start, end, step);

						for (index in indices)
						{
							var newPath = node.path + "[" + index + "]";
							result.push({
								path: newPath,
								value: node.value.get('$index')
							});
						}
					}
				case FilterSelector(filter):
					for (node in fullList)
					{
						var results = queryPaths_ChildFilterSelector(filter, node, rootValue);

						result = result.concat(results);
					}
				default:
					throw pathError_unexpectedElement(selector);
			}
		}

		return result;
	}

	static function buildDescendantList(nodeList:Array<JSONNode>):Array<JSONNode>
	{
		var result:Array<JSONNode> = [];

		for (node in nodeList)
		{
			var keys = node.value.keys();

			var children:Array<JSONNode> = [];

			for (key in keys)
			{
				var isArray = node.value.isArray();
				children.push({
					path: node.path + (isArray ? "[" + key + "]" : "['" + key + "']"),
					value: node.value.get(key)
				});
			}

			var subChildren = buildDescendantList(children);

			result = result.concat(children);
			result = result.concat(subChildren);
		}

		return result;
	}

	static function resolveRelativeNodes(rootNode:JSONNode, relativeNodes:Array<JSONNode>):Array<JSONNode>
	{
		var result:Array<JSONNode> = [];

		for (relativeNode in relativeNodes)
		{
			result.push({
				path: relativeNode.path.replace('@', rootNode.path),
				value: relativeNode.value
			});
		}

		return result;
	}

	static function pathError_noRootIdentifier(element:Element):String
	{
		return 'JSONPath must start with root identifier "$", but got: ${element}';
	}

	static function pathError_unexpectedElement(element:Element):String
	{
		return 'Unexpected element: ${element}';
	}

	static function pathError_singularQueryMultipleResults(nodes:Array<JSONNode>):String
	{
		return 'Got multiple results for singular query: ${nodes}';
	}

	static final DOLLAR:Int = 0x24; // $
	static final AT:Int = 0x40; // @
	static final SINGLE_QUOTE:Int = 0x27; // '
	static final LBRACKET:Int = 0x5B; // [
	static final RBRACKET:Int = 0x5D; // ]

	/**
	 * Split a normalized path $['a']['b']['c'][1] into ['a', 'b', 'c', '1']
	 */
	public static function splitNormalizedPath(path:String):Array<String>
	{
		var index = 0;

		if (StringTools.fastCodeAt(path, index) != DOLLAR)
		{
			throw npathError(path);
		}
		else
		{
			index++;
		}

		var result:Array<String> = [];

		while (true)
		{
			if (index >= path.length)
			{
				return result;
			}
			else if (StringTools.fastCodeAt(path, index) == LBRACKET)
			{
				var start = index;
				var end = index;

				while (true)
				{
					if (StringTools.fastCodeAt(path, end) == RBRACKET)
					{
						break;
					}
					else
					{
						end++;
					}
				}

				if (StringTools.fastCodeAt(path, start) != LBRACKET)
				{
					throw npathError_unexpectedChar(String.fromCharCode(StringTools.fastCodeAt(path, start)));
				}
				if (StringTools.fastCodeAt(path, end) != RBRACKET)
				{
					throw npathError_unexpectedChar(String.fromCharCode(StringTools.fastCodeAt(path, end)));
				}

				var fullElement = path.substring(start, end + 1);
				var element = fullElement.substring(1, fullElement.length - 1);

				if (StringTools.fastCodeAt(element, 0) == SINGLE_QUOTE)
				{
					if (StringTools.fastCodeAt(element, element.length - 1) == SINGLE_QUOTE)
					{
						element = element.substring(1, element.length - 1);
					}
					else
					{
						throw npathError(path);
					}
				}

				result.push(element);
				index = end + 1;
			}
			else
			{
				throw npathError(path);
			}
		}
	}

	static function npathError(path:String):String
	{
		return 'Invalid normalized path: ${path}';
	}

	static function npathError_unexpectedChar(token:String):String
	{
		return 'Unexpected character in normalized path: ${token}';
	}
}

typedef JSONNode =
{
	/**
	 * A normalized path into the query argument.
	 */
	var path:String;

	/**
	 * The value found at the path.
	 */
	var value:JSONData;
}

enum Element
{
	/**
	 * A JSONPath query consists of a root identifier followed by
	 * a sequence of segments (possibly empty) with optional blank space between.
	 * 
	 * Each segment takes in an input node list (the first segment takes in the query value)
	 * and produces an output node list, which the next segment operates on in turn.
	 */
	JSONPathQuery(segments:Array<Element>);

	/**
	 * Represents a JSONPath which is relative to the current node.
	 * Used by filter selectors.
	 */
	RelativeQuery(segments:Array<Element>);

	// Each Segment is either a child segment or a descendant segment.

	/**
	 * A child segment takes a sequence of selectors and selects zero or more children of the input value,
	 * producing a nodelist of the matching values.
	 */
	ChildSegment(selectors:Array<Element>);

	/**
	 * A descendant segment recursively visits the input value and each of its descendants,
	 * producing a nodelist the values matching the provided selectors.
	 */
	DescendantSegment(selectors:Array<Element>);

	// Each Selector produces a nodelist consisting of zero or more children of the input value.

	/**
	 * Selects at most one member value of an object node whose name equals the provided member name,
	 * or nothing if there is no such value. Nothing is selected from non-objects.
	 */
	NameSelector(name:String);

	/**
	 * Selects the nodes of all children of an object or array.
	 * Nothing is selected from primatives.
	 */
	WildcardSelector();

	/**
	 * Selects at most one array element value of an array node.
	 * Nothing is selected if the index lies outside the range of the array, or if the input node is not an array.
	 * A negative index selector counts from the array end backwards.
	 */
	IndexSelector(index:Int);

	/**
	 * Selects a slice of an array node, from start to end, incremented by step.
	 */
	ArraySliceSelector(?start:Int, ?end:Int, ?step:Int);

	/**
	 * Filter selectors iterate over objects or arrays, and evaluate a logical expression for each element or member,
	 * which decides if the node is selected.
	 */
	FilterSelector(logicalExpression:Element);

	// Each Logical Expression can be evaluated to a LogicalType (either true or false) for a given input value.

	/**
	 * A boolean OR of each of the logical subexpressions.
	 */
	LogicalOrExpr(elements:Array<Element>);

	/**
	 * A boolean AND of each of the logical subexpressions.
	 */
	LogicalAndExpr(elements:Array<Element>);

	/**
	 * A boolean NOT of the logical subexpression.
	 */
	LogicalNotExpr(element:Element);

	/**
	 * A test expression which tests the result of a function expression.
	 * For boolean results, checks if the result is True.
	 * For Node results, checks if the result is non-empty.
	 */
	// NOTE: Move LogicalNotExpr one layer up.
	// Input can be one of: FilterQuery, FunctionExpression
	LogicalTestQueryExpr(element:Element);

	/**
	 * A comparsion expression evalutes multiple primitive values against each other.
	 * Comparables include PrimitiveLiterals, or SingularQuery, or FunctionExpression.
	 * Operators include: ==, !=, <, <=, >, >=
	 */
	LogicalComparisionExpr(compareA:Element, op:String, compareB:Element);

	/**
	 * Either a number, string, true, false, or null.
	 */
	PrimitiveLiteralExpr(value:PrimitiveLiteral);

	/**
	 * One of either JSONPathQuery (absolute) or RelativeQuery (relative).
	 */
	FilterQuery(element:Element);

	/**
	 * One of either JSONPathQuery (absolute) or RelativeQuery (relative), but Segments of these can only be Name or Index.
	 */
	SingularQuery(element:Element);

	/**
	 * A function expression which evaluates a named function extension.
	 * Arguments can be one of PrimitiveLiteral, FilterQuery, LogicalExpression, or FunctionExpression
	 */
	FunctionExpressionElement(name:String, arguments:Array<Element>);
}

@:access(json.path.JSONPathParser)
class JSONPathParser
{
	var tokens:Array<Token>;
	var readPos:Int = 0;

	public function new() {}

	public function parse(path:String):Null<Element>
	{
		tokens = new JSONPathLexer().tokenize(path);

		if (tokens.length == 0)
		{
			return null;
		}

		var result:Element = consumeToken_JSONPathQuery();

		if (!isEnd())
		{
			throw parserError_unexpectedToken(peekToken());
		}

		return result;
	}

	function consumeToken_JSONPathQuery():Element
	{
		var token = popToken();
		switch (token)
		{
			case Token.Dollar:
				return Element.JSONPathQuery(consumeTokens_Segment());
			default:
				throw parserError_unexpectedToken_rootSelector(token);
		}
	}

	function consumeToken_RelativeQuery():Element
	{
		var token = popToken();
		switch (token)
		{
			case Token.At:
				return Element.RelativeQuery(consumeTokens_Segment());
			default:
				throw parserError_unexpectedToken(token);
		}
	}

	function consumeTokens_Segment():Array<Element>
	{
		var result:Array<Element> = [];
		while (!isEnd())
		{
			switch (peekToken())
			{
				case Whitespace:
					var token = popToken();
					continue;

				// Child Segments

				case Brackets(values):
					var token = popToken();
					result.push(Element.ChildSegment(consumeTokens_BracketedSelection(values)));

				case Dot:
					var token = popToken();
					result.push(Element.ChildSegment([consumeTokens_DotSelection()]));

				// Descendant Segments

				case DoubleDot:
					var token = popToken();
					switch (peekToken())
					{
						case Brackets(values):
							var token = popToken();
							result.push(Element.DescendantSegment(consumeTokens_BracketedSelection(values)));
						case Asterisk:
							var token = popToken();
							result.push(Element.DescendantSegment([Element.WildcardSelector]));
						case MemberName(name):
							var token = popToken();
							result.push(Element.DescendantSegment([Element.NameSelector(name)]));
						case StringLiteral(name):
							var token = popToken();
							// TODO: Handle $.."key"?
							// result.push(Element.DescendantSegment([Element.NameSelector(name)]));
							throw parserError_unexpectedToken_doubleDotSelector_stringLiteral(name);
						default:
							throw parserError_unexpectedToken_doubleDotSelector(peekToken());
					}

				default:
					// throw parserError_unexpectedToken(token);
					return result;
			}
		}

		return result;
	}

	function consumeTokens_BracketedSelection(values:Array<Token>):Array<Element>
	{
		var subParser = new JSONPathParser();

		@:privateAccess
		{
			subParser.tokens = values;
			var result = subParser.consumeTokens_Selectors();
			if (!subParser.isEnd())
			{
				throw parserError_unexpectedToken(subParser.peekToken());
			}
			return result;
		}
	}

	function consumeTokens_DotSelection():Element
	{
		var token = popToken();
		switch (token)
		{
			case Asterisk:
				return Element.WildcardSelector;
			case MemberName(name):
				return Element.NameSelector(name);
			case IntegerLiteral(value):
				// Handle $.2 as $['2']
				return Element.NameSelector('$value');
			case StringLiteral(value):
				// TODO: Handle $."key"?
				// return Element.NameSelector(value);
				throw parserError_unexpectedToken_dotSelector_stringLiteral(value);
			default:
				throw parserError_unexpectedToken_dotSelector(token);
		}
	}

	function consumeTokens_Selectors():Array<Element>
	{
		var result:Array<Element> = [];
		while (!isEnd())
		{
			var token = popToken();
			switch (token)
			{
				case Whitespace:
					continue;
				case StringLiteral(name): // NameSelector
					result.push(Element.NameSelector(name));
				case MemberName(name): // NameSelector
					result.push(Element.NameSelector(name));
				case Asterisk: // WildcardSelector
					result.push(Element.WildcardSelector);
				case IntegerLiteral(number): // Index or ArraySlice
					// Look at the token after.
					switch (peekNonWhitespaceToken())
					{
						case Colon:
							// ArraySlice
							result.push(consumeTokens_ArraySliceSelector(token));
						default:
							// Index
							result.push(Element.IndexSelector(number));
					}
				case Colon:
					// ArraySlice
					result.push(consumeTokens_ArraySliceSelector(token));

				case Question:
					result.push(consumeTokens_FilterSelector());
				default:
					throw parserError_unexpectedToken(token);
			}

			// Skip whitespace.
			popWhitespace();

			// See if there's a next token.
			switch (peekToken())
			{
				case Comma:
					var token = popToken();
					continue;
				case null:
					break;
				default:
					throw parserError_unexpectedToken(peekToken());
			}
		}
		return result;
	}

	function consumeTokens_ArraySliceSelector(firstToken:Token):Element
	{
		var start:Null<Int> = null;
		var end:Null<Int> = null;
		var step:Null<Int> = null;

		var emptyStart:Bool = false;

		if (firstToken != null)
		{
			switch (firstToken)
			{
				case IntegerLiteral(number):
					start = number;
				case Colon:
					emptyStart = true;
				case NumberLiteral(value):
					throw parserError_unexpectedToken(firstToken);
				default:
					throw parserError_unexpectedToken(firstToken);
			}
		}

		popWhitespace();

		if (!emptyStart)
		{
			var token = popToken();
			if (token != Colon)
				throw parserError_unexpectedToken(token);
		}

		popWhitespace();

		var token = peekToken();
		switch (token)
		{
			case IntegerLiteral(number):
				popToken();
				end = number;
			default:
				// Do nothing.
		}

		popWhitespace();

		var token = peekToken();
		if (token != Colon)
		{
			return Element.ArraySliceSelector(start, end, step);
		}
		else
		{
			popToken();
		}

		popWhitespace();

		var token = peekToken();
		switch (token)
		{
			case IntegerLiteral(number):
				popToken();
				step = number;
			default:
				// Do nothing.
		}

		return Element.ArraySliceSelector(start, end, step);
	}

	function consumeTokens_FilterSelector():Element
	{
		return Element.FilterSelector(consumeTokens_logicalOrExpr());
	}

	/**
	 * Recursively locate LogicalOrExpr and LogicalAndExpr which have only one element and flatten them.
	 */
	function consumeTokens_cleanupFilterSelector(element:Element):Element
	{
		switch (element)
		{
			case Element.LogicalOrExpr(elements):
				if (elements.length == 1)
				{
					return consumeTokens_cleanupFilterSelector(elements[0]);
				}
				else
				{
					var result:Array<Element> = [];
					for (element in elements)
					{
						result.push(consumeTokens_cleanupFilterSelector(element));
					}
					return Element.LogicalOrExpr(result);
				}
			case Element.LogicalAndExpr(elements):
				if (elements.length == 1)
				{
					return consumeTokens_cleanupFilterSelector(elements[0]);
				}
				else
				{
					var result:Array<Element> = [];
					for (element in elements)
					{
						result.push(consumeTokens_cleanupFilterSelector(element));
					}
					return Element.LogicalAndExpr(result);
				}
			default:
				return element;
		}
	}

	function consumeTokens_logicalOrExpr():Element
	{
		var result:Array<Element> = [];

		result.push(consumeTokens_cleanupFilterSelector(consumeTokens_logicalAndExpr()));

		popWhitespace();

		while (peekToken() == LogicalOr)
		{
			var token = popToken();
			result.push(consumeTokens_cleanupFilterSelector(consumeTokens_logicalAndExpr()));
		}

		return Element.LogicalOrExpr(result);
	}

	function consumeTokens_logicalAndExpr():Element
	{
		var result:Array<Element> = [];

		result.push(consumeTokens_logicalBasicExpr());

		popWhitespace();

		while (peekToken() == LogicalAnd)
		{
			var token = popToken();
			result.push(consumeTokens_logicalBasicExpr());
		}

		return Element.LogicalAndExpr(result);
	}

	function consumeTokens_logicalBasicExpr():Element
	{
		popWhitespace();

		switch (peekToken())
		{
			case Parens(values):
				var token = popToken();
				var subParser = new JSONPathParser();
				@:privateAccess
				{
					subParser.tokens = values;
					var result = consumeTokens_cleanupFilterSelector(subParser.consumeTokens_logicalOrExpr());
					if (!subParser.isEnd())
					{
						throw parserError_unexpectedToken(subParser.peekToken());
					}
					return result;
				}
			case LogicalNot:
				var token = popToken();
				popWhitespace();
				switch (peekToken())
				{
					case Parens(values):
						var token = popToken();
						var subParser = new JSONPathParser();
						@:privateAccess
						{
							subParser.tokens = values;
							var result = consumeTokens_cleanupFilterSelector(subParser.consumeTokens_logicalOrExpr());
							if (!subParser.isEnd())
							{
								throw parserError_unexpectedToken(subParser.peekToken());
							}
							return Element.LogicalNotExpr(result);
						}
					case MemberName(_):
						return Element.LogicalNotExpr(consumeTokens_logicalBasicExpr());
					case Dollar:
						return Element.LogicalNotExpr(consumeTokens_logicalBasicExpr());
					case At:
						return Element.LogicalNotExpr(consumeTokens_logicalBasicExpr());
					default:
						throw parserError_unexpectedToken(peekToken());
				}
			case Dollar:
				return consumeTokens_comparisonOrTest();
			case At:
				return consumeTokens_comparisonOrTest();
			case StringLiteral(value):
				return consumeTokens_comparisonOrTest();
			case NumberLiteral(value):
				return consumeTokens_comparisonOrTest();
			case IntegerLiteral(value):
				return consumeTokens_comparisonOrTest();
			case MemberName(name):
				return consumeTokens_comparisonOrTest();
			default:
				throw parserError_unexpectedToken(peekToken());
		}
	}

	function consumeTokens_FunctionExpression():Array<Element>
	{
		switch (peekToken())
		{
			case Parens(values):
				var token = popToken();
				var subParser = new JSONPathParser();
				@:privateAccess
				{
					subParser.tokens = values;
					var result = subParser.consumeTokens_FunctionExpressionArgs();
					if (!subParser.isEnd())
					{
						throw parserError_unexpectedToken(subParser.peekToken());
					}
					return result;
				}
			default:
				throw parserError_unexpectedToken(peekToken());
		}
	}

	function consumeTokens_FunctionExpressionArgs():Array<Element>
	{
		var result:Array<Element> = [];
		while (!isEnd())
		{
			popWhitespace();

			switch (peekToken())
			{
				case StringLiteral(value):
					var token = popToken();
					result.push(Element.PrimitiveLiteralExpr(StringLiteral(value)));
				case NumberLiteral(value):
					var token = popToken();
					result.push(Element.PrimitiveLiteralExpr(NumberLiteral(value)));
				case IntegerLiteral(value):
					var token = popToken();
					result.push(Element.PrimitiveLiteralExpr(IntegerLiteral(value)));
				case MemberName(value):
					switch (value)
					{
						case "true":
							var token = popToken();
							result.push(Element.PrimitiveLiteralExpr(BooleanLiteral(true)));
						case "false":
							var token = popToken();
							result.push(Element.PrimitiveLiteralExpr(BooleanLiteral(false)));
						case "null":
							var token = popToken();
							result.push(Element.PrimitiveLiteralExpr(NullLiteral));
						default:
							if (FunctionExpression.isValidFunctionExpression(value))
							{
								var token = popToken();
								result.push(Element.FunctionExpressionElement(value, consumeTokens_FunctionExpression()));
							}
							else
							{
								throw parserError_unexpectedToken(peekToken());
							}
					}
				case At:
					result.push(consumeTokens_comparisonOrTest());
				case Dollar:
					result.push(consumeTokens_comparisonOrTest());
				default:
					throw parserError_unexpectedToken(peekToken());
			}

			popWhitespace();

			switch (peekToken())
			{
				case Comma:
					var token = popToken();
					continue;
				case null:
					break;
				default:
					throw parserError_unexpectedToken(peekToken());
			}
		}

		return result;
	}

	function consumeTokens_comparisonOrTest():Element
	{
		var left:Element = null;
		switch (peekToken())
		{
			case StringLiteral(value):
				popToken();
				left = PrimitiveLiteralExpr(StringLiteral(value));
			case NumberLiteral(value):
				popToken();
				left = PrimitiveLiteralExpr(NumberLiteral(value));
			case IntegerLiteral(value):
				popToken();
				left = PrimitiveLiteralExpr(IntegerLiteral(value));
			case Dollar:
				left = Element.FilterQuery(consumeToken_JSONPathQuery());
			case At:
				left = Element.FilterQuery(consumeToken_RelativeQuery());
			case MemberName(name):
				switch (name)
				{
					case "true":
						left = Element.PrimitiveLiteralExpr(BooleanLiteral(true));
					case "false":
						left = Element.PrimitiveLiteralExpr(BooleanLiteral(false));
					case "null":
						left = Element.PrimitiveLiteralExpr(NullLiteral);
					default:
						if (FunctionExpression.isValidFunctionExpression(name))
						{
							var token = popToken();
							left = Element.FunctionExpressionElement(name, consumeTokens_FunctionExpression());
						}
						else
						{
							throw parserError_unexpectedToken(peekToken());
						}
				}
			default:
				throw parserError_unexpectedToken(peekToken());
		}

		popWhitespace();

		var token = peekToken();
		switch (token)
		{
			case Comparison(op):
				var token = popToken();
				return Element.LogicalComparisionExpr(left, op, consumeToken_comparable());
			case Comma:
				return Element.LogicalTestQueryExpr(left);
			case null:
				return Element.LogicalTestQueryExpr(left);
			default:
				return Element.LogicalTestQueryExpr(left);
				// throw parserError_unexpectedToken(token);
		}
	}

	function consumeToken_comparable():Element
	{
		switch (peekToken())
		{
			case Dollar: // Singular query
				return Element.FilterQuery(consumeToken_JSONPathQuery());
			case At: // Singular query
				return Element.FilterQuery(consumeToken_RelativeQuery());
			case IntegerLiteral(number): // Integer
				var token = popToken();
				return Element.PrimitiveLiteralExpr(IntegerLiteral(number));
			case NumberLiteral(number): // Float
				var token = popToken();
				return Element.PrimitiveLiteralExpr(NumberLiteral(number));
			case StringLiteral(value): // String
				var token = popToken();
				return Element.PrimitiveLiteralExpr(StringLiteral(value));
			case MemberName(value):
				switch (value)
				{
					case "true":
						var token = popToken();
						return Element.PrimitiveLiteralExpr(BooleanLiteral(true));
					case "false":
						var token = popToken();
						return Element.PrimitiveLiteralExpr(BooleanLiteral(false));
					case "null":
						var token = popToken();
						return Element.PrimitiveLiteralExpr(NullLiteral);
					default:
						if (FunctionExpression.isValidFunctionExpression(value))
						{
							var token = popToken();
							return Element.FunctionExpressionElement(value, consumeTokens_FunctionExpression());
						}
						else
						{
							throw parserError_unexpectedToken(peekToken());
						}

						throw parserError_unexpectedToken_comparable_memberName(value);
				}
			case Whitespace:
				var token = popToken();
				return consumeToken_comparable();
			default:
				throw parserError_unexpectedToken_comparable(peekToken());
		}
	}

	function popWhitespace():Void
	{
		while (peekToken() == Whitespace)
		{
			var token = popToken();
		}
	}

	function popToken():Null<Token>
	{
		return tokens[readPos++];
	}

	function peekToken(index:Int = 0):Null<Token>
	{
		if (readPos + index >= tokens.length)
			return null;
		return tokens[readPos + index];
	}

	function peekNonWhitespaceToken(index:Int = 0):Null<Token>
	{
		while (peekToken(index) == Whitespace)
		{
			index++;
		}
		return peekToken(index);
	}

	function previewTokens():Array<Token>
	{
		return tokens.slice(readPos);
	}

	function isEnd():Bool
	{
		return readPos >= tokens.length;
	}

	static function parserError_unexpectedToken(token:Token):String
	{
		return 'Unexpected token: ${token}';
	}

	static function parserError_unexpectedToken_rootSelector(token:Token):String
	{
		return 'JSONPath query must start with "$", but got token: ${token}';
	}

	static function parserError_unexpectedToken_comparable_memberName(input:String):String
	{
		return 'Expected comparable value, but got member name: ${input}';
	}

	static function parserError_unexpectedToken_comparable(token:Token):String
	{
		return 'Expected comparable value, but got token: ${token}';
	}

	static function parserError_unexpectedToken_dotSelector(token:Token):String
	{
		return 'Expected member name or array index after ".", but got token: ${token}';
	}

	static function parserError_unexpectedToken_dotSelector_stringLiteral(input:String):String
	{
		return 'Expected member name or array index after ".", but got string literal: ${input}';
	}

	static function parserError_unexpectedToken_doubleDotSelector(token:Token):String
	{
		return 'Expected member name or array index after "..", but got token: ${token}';
	}

	static function parserError_unexpectedToken_doubleDotSelector_stringLiteral(input:String):String
	{
		return 'Expected member name or array index after "..", but got string literal: ${input}';
	}
}

enum Token
{
	/**
	 * Every JSONPath query (except those inside filter expressions)
	 * must begin with the root identifier `$`.
	 */
	Dollar;

	/**
	 * One or more blank spaces.
	 */
	Whitespace;

	/**
	 * A string surrounded by single or double quotes
	 */
	StringLiteral(value:String);

	/**
	 * A string starting with a non-numeric character, followed by zero or more characters (possibly numeric)
	 */
	MemberName(value:String);

	/**
	 * A single `*` used as a wildcard selector
	 */
	Asterisk;

	/**
	 * An integer number, such as that used for an array index selector
	 */
	IntegerLiteral(value:Int);

	/**
	 * A floating point number
	 */
	NumberLiteral(value:Float);

	/**
	 * A single `:` used as part of an array slice selector
	 */
	Colon;

	/**
	 * A single `,` used to separate selectors in a bracketed selection
	 */
	Comma;

	/**
	 * A question mark `?` used to start a filter selector
	 */
	Question;

	/**
	 * An at `@` used to start a filter query
	 */
	At;

	/**
	 * A single `.` used for a segment shorthand.
	 */
	Dot;

	/**
	 * A double dot `..` used for descendant segments.
	 */
	DoubleDot;

	/**
	 * A comparison operator, one of `==`, `!=`, `>=`, `>`, `<=`, `<`
	 */
	Comparison(op:String);

	/**
	 * A set of expressions surrounded by parentheses
	 */
	Parens(values:Array<Token>);

	/**
	 * A set of expressions surrounded by brackets
	 */
	Brackets(values:Array<Token>);

	/**
	 * A set of expressions surrounded by curly braces
	 */
	Braces(values:Array<Token>);

	/**
	 * The `||` used to indicate a logical OR expression.
	 */
	LogicalOr;

	/**
	 * The `&&` used to indicate a logical OR expression.
	 */
	LogicalAnd;

	/**
	 * The `!` used to indicate a logical NOT expression.
	 */
	LogicalNot;
}

/**
 * Breaks down an input string into a list of Tokens, without otherwise validating syntax.
 */
class JSONPathLexer
{
	static final BACKSPACE:Int = 0x08; // \b
	static final TAB:Int = 0x09; // \t
	static final NEWLINE:Int = 0x0A; // \n
	static final FORMFEED:Int = 0x0C; // \f
	static final CARRIAGE:Int = 0x0D; // \r
	static final SPACE:Int = 0x20; // ' '
	static final EXCLAMATION:Int = 0x21; // !
	static final DOUBLE_QUOTE:Int = 0x22; // "
	static final DOLLAR:Int = 0x24; // $
	static final AMPERSAND:Int = 0x26; // &
	static final SINGLE_QUOTE:Int = 0x27; // '
	static final LPAREN:Int = 0x28; // (
	static final RPAREN:Int = 0x29; // )
	static final ASTERISK:Int = 0x2A; // *
	static final PLUS:Int = 0x2B; // +
	static final COMMA:Int = 0x2C; // ,
	static final MINUS:Int = 0x2D; // -
	static final PERIOD:Int = 0x2E; // .
	static final SLASH:Int = 0x2F; // /
	static final COLON:Int = 0x3A; // :
	static final SEMICOLON:Int = 0x3B; // ;
	static final LESS:Int = 0x3C; // <
	static final EQUALS:Int = 0x3D; // =
	static final GREATER:Int = 0x3E; // >
	static final QUESTION:Int = 0x3F; // ?
	static final AT:Int = 0x40; // @
	static final LBRACKET:Int = 0x5B; // [
	static final ESCAPE:Int = 0x5C; // \
	static final RBRACKET:Int = 0x5D; // ]
	static final CARET:Int = 0x5E; // ^
	static final UNDERSCORE:Int = 0x5F; // _
	static final LBRACE:Int = 0x7B; // {
	static final BAR:Int = 0x7C; // |
	static final RBRACE:Int = 0x7D; // }

	// lowercase
	static final B:Int = 0x62; // b
	static final D:Int = 0x64; // d
	static final E:Int = 0x65; // e
	static final F:Int = 0x66; // f
	static final N:Int = 0x6E; // n
	static final R:Int = 0x72; // r
	static final T:Int = 0x74; // t
	static final U:Int = 0x75; // u

	// uppercase
	static final A_U:Int = 0x41; // A
	static final B_U:Int = 0x42; // B
	static final C_U:Int = 0x43; // C
	static final D_U:Int = 0x44; // D
	static final E_U:Int = 0x45; // E
	static final F_U:Int = 0x46; // F

	// digits
	static final ZERO:Int = 0x30; // 0
	static final NINE:Int = 0x39; // 9

	static final DIGIT:Array<Int> = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39];

	static final HEXDIG:Array<Int> = [
		0x30,
		0x31,
		0x32,
		0x33,
		0x34,
		0x35,
		0x36,
		0x37,
		0x38,
		0x39,
		// Uppercase
		0x41,
		0x42,
		0x43,
		0x44,
		0x45,
		0x46,
		// Lowercase
		0x61,
		0x62,
		0x63,
		0x64,
		0x65,
		0x66
	];

	// The input string
	var input:String;

	// The current read position
	var readPos:Int;

	var readLine:Int;
	var readCol:Int;

	// The position of the current token.
	var tokenMin:Int;
	var tokenMax:Int;

	// The current token list
	var tokens:Array<Token>;

	public function new()
	{
		tokens = new Array<Token>();

		readPos = 0;
		readLine = 0;
		readCol = 0;

		tokenMin = 0;
		tokenMax = 0;
	}

	public function tokenize(input:String):Array<Token>
	{
		this.input = input;

		while (!eof())
		{
			var tk = readToken();
			pushToken(tk);
		}

		return tokens;
	}

	#if !debug inline #end function pushToken(token:Token):Void
	{
		tokens.push(token);
	}

	//
	// TOKEN HANDLERS
	//
	#if !debug inline #end function readToken():Token
	{
		switch (peekChar())
		{
			case DOLLAR:
				var char = popChar();

				return Token.Dollar;
			case ASTERISK:
				var char = popChar();

				return Token.Asterisk;
			case COLON:
				var char = popChar();

				return Token.Colon;
			case COMMA:
				var char = popChar();

				return Token.Comma;
			case QUESTION:
				var char = popChar();

				return Token.Question;
			case AT:
				var char = popChar();

				return Token.At;

			case PERIOD:
				return readToken_distinguish_period();

			case GREATER | LESS | EQUALS:
				return readToken_comparison();
			case TAB | NEWLINE | CARRIAGE | SPACE:
				return readToken_whitespace();
			case SINGLE_QUOTE:
				return readToken_stringLiteral(true);
			case DOUBLE_QUOTE:
				return readToken_stringLiteral(false);
			case MINUS:
				return readToken_numberLiteral();
			case BAR:
				return readToken_logicalOr();
			case AMPERSAND:
				return readToken_logicalAnd();
			case EXCLAMATION:
				return readToken_distinguish_exclamation();
			case isDigit(_) => true:
				return readToken_numberLiteral();

			case LPAREN:
				return readToken_parens();
			case LBRACE:
				return readToken_braces();
			case LBRACKET:
				return readToken_brackets();

			case RPAREN:
				throw formatError_UnexpectedChar(')');
			case RBRACE:
				throw formatError_UnexpectedChar('}');
			case RBRACKET:
				throw formatError_UnexpectedChar(']');

			case isNameFirst(_) => true:
				return readToken_memberName();

			default:
				throw formatError_UnexpectedChar(String.fromCharCode(peekChar()));
		}
	}

	#if !debug inline #end function readToken_distinguish_exclamation():Token
	{
		var char = popChar();

		if (peekChar() == EQUALS)
		{
			var char = popChar();
			return Token.Comparison('!=');
		}
		else
		{
			return Token.LogicalNot;
		}
	}

	#if !debug inline #end function readToken_distinguish_period():Token
	{
		var char = popChar();

		if (peekChar() == PERIOD)
		{
			var char = popChar();
			return Token.DoubleDot;
		}
		else
		{
			return Token.Dot;
		}
	}

	#if !debug inline #end function readToken_parens():Token
	{
		// Consume the opening paren
		var char = popChar();

		var tokens = readToken_consumeContents(RPAREN);

		// Consume the closing paren
		var char = popChar();

		return Token.Parens(tokens);
	}

	#if !debug inline #end function readToken_brackets():Token
	{
		// Consume the opening paren
		var char = popChar();

		var tokens = readToken_consumeContents(RBRACKET);

		// Consume the closing paren
		var char = popChar();

		return Token.Brackets(tokens);
	}

	#if !debug inline #end function readToken_braces():Token
	{
		// Consume the opening paren
		var char = popChar();

		var tokens = readToken_consumeContents(RBRACE);

		// Consume the closing paren
		var char = popChar();

		return Token.Braces(tokens);
	}

	/**
	 * Consume tokens until we find the given character (such as a closing parenthesis)
	 */
	#if !debug inline #end function readToken_consumeContents(expected:Int):Array<Token>
	{
		var startPos = readPos;
		// Read tokens until we find the closing paren
		var tokens = [];
		while (!eof() && peekChar() != expected)
		{
			var tk = readToken();
			tokens.push(tk);
		}
		if (eof())
			throw formatError_Unclosed(String.fromCharCode(expected), startPos);
		return tokens;
	}

	#if !debug inline #end function readToken_comparison():Token
	{
		var char = popChar();

		switch (char)
		{
			case GREATER:
				if (peekChar() == EQUALS)
				{
					var char = popChar();
					return Token.Comparison('>=');
				}
				else
				{
					return Token.Comparison('>');
				}
			case LESS:
				if (peekChar() == EQUALS)
				{
					var char = popChar();
					return Token.Comparison('<=');
				}
				else
				{
					return Token.Comparison('<');
				}
			case EQUALS:
				if (!(peekChar() == EQUALS))
					throw formatError_UnexpectedChar(String.fromCharCode(peekChar()));
				var char = popChar();
				return Token.Comparison('==');
			default:
				throw formatError_UnexpectedChar(String.fromCharCode(char));
		}
	}

	#if !debug inline #end function readToken_logicalOr():Token
	{
		var char = popChar();
		if (eof() || peekChar() != BAR)
			throw formatError_UnexpectedChar(String.fromCharCode(char));
		var char = popChar();

		return Token.LogicalOr;
	}

	#if !debug inline #end function readToken_logicalAnd():Token
	{
		var char = popChar();
		if (eof() || peekChar() != AMPERSAND)
			throw formatError_UnexpectedChar(String.fromCharCode(char));
		var char = popChar();

		return Token.LogicalAnd;
	}

	#if !debug inline #end function readToken_whitespace():Token
	{
		// Read until we find a non-whitespace character
		var char = peekChar();
		while (!eof() && isWhitespace(char))
		{
			popChar();
			char = peekChar();
		}

		return Token.Whitespace;
	}

	#if !debug inline #end function readToken_numberLiteral():Token
	{
		var result = '';

		var isFloat = false;
		var char = peekChar();
		while (!eof() && (isDigit(char) || char == MINUS || char == PERIOD || char == E || char == PLUS))
		{
			if (char == PERIOD || char == E || char == PLUS)
				isFloat = true;
			result += readToken_unescaped(false);
			char = peekChar();
		}

		if (isFloat)
		{
			var num = Std.parseFloat(result);
			if (Math.isNaN(num))
				throw formatError_InvalidNumber(result);

			return Token.NumberLiteral(num);
		}
		else
		{
			var num = Std.parseInt(result);
			if (num == null)
				throw formatError_InvalidNumber(result);

			return Token.IntegerLiteral(num);
		}
	}

	#if !debug inline #end function readToken_memberName():Token
	{
		var result = '';

		var char = popChar();
		if (!isNameFirst(char))
			throw formatError_UnexpectedChar(String.fromCharCode(char));
		result += String.fromCharCode(char);

		var char = peekChar();
		// Allow - and digits in member names but not first character.
		while (!eof() && (isNameFirst(char) || isDigit(char) || char == MINUS))
		{
			result += readToken_unescaped(false);
			char = peekChar();
		}

		return Token.MemberName(result);
	}

	#if !debug inline #end function readToken_stringLiteral(singleQuote:Bool):Token
	{
		var result = '';

		var startQuote = popChar();

		var char = peekChar();
		while (!eof() && singleQuote ? char != SINGLE_QUOTE : char != DOUBLE_QUOTE)
		{
			if (char == ESCAPE)
			{
				var escape = popChar();
				result += readToken_escapable();
			}
			else
			{
				result += readToken_unescaped(true);
			}

			char = peekChar();
		}

		var endQuote = popChar();

		return Token.StringLiteral(result);
	}

	#if !debug inline #end function readToken_unescaped(allowQuotes:Bool):String
	{
		if (eof())
			throw formatError_UnexpectedEnd();

		var char = popChar();

		// Exclude control characters
		if (char < 0x20)
			throw formatError_UnexpectedChar(String.fromCharCode(char));

		// Exclude surrogate code points
		if (char > 0xD7FF && char < 0xE000)
			throw formatError_UnexpectedChar(String.fromCharCode(char));

		// Exclude very high Unicode characters
		if (char > 0x10FFFF)
			throw formatError_UnexpectedChar(String.fromCharCode(char));

		// Exclude quotes and backslash
		if (char == ESCAPE)
			throw formatError_UnexpectedChar(String.fromCharCode(char));

		if (!allowQuotes && char == SINGLE_QUOTE)
			throw formatError_UnexpectedChar(String.fromCharCode(char));
		if (!allowQuotes && char == DOUBLE_QUOTE)
			throw formatError_UnexpectedChar(String.fromCharCode(char));

		return String.fromCharCode(char);
	}

	#if !debug inline #end function readToken_escapable():String
	{
		var char = popChar();
		// Handle escape sequences
		switch (char)
		{
			case SINGLE_QUOTE | DOUBLE_QUOTE | ESCAPE | SLASH:
				return String.fromCharCode(char);
			case B:
				return String.fromCharCode(BACKSPACE);
			case F:
				return String.fromCharCode(FORMFEED);
			case N:
				return String.fromCharCode(NEWLINE);
			case R:
				return String.fromCharCode(CARRIAGE);
			case T:
				return String.fromCharCode(TAB);
			case U:
				return readToken_hexchar();
			default:
				throw formatError_UnexpectedChar(String.fromCharCode(char));
		}
	}

	#if !debug inline #end function readToken_hexchar():String
	{
		var hexStr = '0x';

		while (true)
		{
			if (eof())
				throw formatError_UnexpectedEnd();
			if (HEXDIG.indexOf(peekChar()) == -1)
				break;

			hexStr += String.fromCharCode(popChar());
		}

		var hexCode = Std.parseInt(hexStr);
		if (hexCode == null)
			throw formatError_UnexpectedChar(hexStr);

		if (hexCode >= 0xD800 && hexCode <= 0xDBFF)
		{
			// High surrogate
			if (peekChar() == ESCAPE && peekChar(1) == U)
			{
				popChar();
				popChar();
				var lowChar = readToken_hexchar();
				var lowCode = Std.parseInt(lowChar);
				var fullValue = (hexCode - 0xD800) * 0x400 + (lowCode - 0xDC00) + 0x10000;
				return String.fromCharCode(fullValue);
			}
			else
			{
				return String.fromCharCode(hexCode);
			}
		}
		else if (hexCode >= 0xDC00 && hexCode <= 0xDFFF)
		{
			// Low surrogate
			return '${hexStr}';
		}
		else if (hexCode > 0xFFFF)
		{
			// Unicode code point out of range
			throw formatError_UnsupportedUnicode(hexStr);
		}
		else
		{
			// Normal code point
			return String.fromCharCode(hexCode);
		}
	}

	//
	// INPUT HANDLERS
	//
	#if !debug inline #end function popChar():Int
	{
		var char = StringTools.fastCodeAt(input, readPos++);
		if (char == NEWLINE)
		{
			readLine++;
			readCol = 0;
		}
		else
		{
			readCol++;
		}
		return char;
	}

	#if !debug inline #end function peekChar(index:Int = 0):Int
	{
		return StringTools.fastCodeAt(input, readPos + index);
	}

	#if !debug inline #end function eof():Bool
	{
		return StringTools.isEof(peekChar());
	}

	//
	// CHARACTER HELPERS
	//
	#if !debug inline #end function isDigit(char:Int):Bool
	{
		return char >= 0x30 && char <= 0x39;
	}

	#if !debug inline #end function isWhitespace(char:Int):Bool
	{
		return [TAB, NEWLINE, CARRIAGE, SPACE].indexOf(char) != -1;
	}

	#if !debug inline #end function isLetter(char:Int):Bool
	{
		return (char >= 0x41 && char <= 0x5A) || (char >= 0x61 && char <= 0x7A);
	}

	#if !debug inline #end function isAlphanumeric(char:Int):Bool
	{
		return isLetter(char) || isDigit(char);
	}

	#if !debug inline #end function isNameFirst(char:Int):Bool
	{
		if (isReserved(char))
			return false;

		return isLetter(char) || char == UNDERSCORE || (char >= 0x80 && char <= 0xD7FF) || (char >= 0xE000 && char <= 0x10FFFF);
	}

	#if !debug inline #end function isReserved(char:Int):Bool
	{
		return [PERIOD].indexOf(char) != -1;
	}

	//
	// ERROR HANDLERS
	//
	#if !debug inline #end function formatError_UnexpectedEnd():String
	{
		return 'Unexpected end of input at pos ${readPos}';
	}

	#if !debug inline #end function formatError_Unclosed(char:String, startPos:Int):String
	{
		return 'Unclosed "${char}" starting at pos ${startPos}';
	}

	#if !debug inline #end function formatError_InvalidNumber(num:String):String
	{
		return 'Invalid number at pos ${readPos + 1}: ${num}';
	}

	#if !debug inline #end function formatError_UnexpectedChar(char:String):String
	{
		return 'Unexpected character at pos ${readPos + 1}: ${char}';
	}

	#if !debug inline #end function formatError_UnsupportedUnicode(hexStr:String):String
	{
		return 'Unsupported Unicode at pos ${readPos + 1}: ${hexStr}';
	}
}
