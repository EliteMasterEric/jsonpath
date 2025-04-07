package json.path;

import json.path.PrimitiveLiteral.PrimitiveLiteralTools;

class FunctionExpression
{
	static final VALID_FUNCTIONS:Array<String> = ["length", "count", "match", "search", "value"];

	#if jsonpath_bonus
	static final VALID_FUNCTIONS_BONUS:Array<String> = ["indexOf"];
	#end

	public static function isValidFunctionExpression(name:String):Bool
	{
		// Allow bonus functions if they are enabled
		#if jsonpath_bonus
		if (VALID_FUNCTIONS_BONUS.indexOf(name) != -1) return true;
		#end
		return VALID_FUNCTIONS.indexOf(name) != -1;
	}

	public static function evaluateFunction(name:String, arguments:Array<PrimitiveLiteral>):PrimitiveLiteral
	{
		switch (name)
		{
			case "length":
				return evaluateFunction_length(arguments);
			case "count":
				return evaluateFunction_count(arguments);
			case "match":
				return evaluateFunction_match(arguments);
			case "search":
				return evaluateFunction_search(arguments);
			case "value":
				return evaluateFunction_value(arguments);
			#if jsonpath_bonus
			case "indexOf":
				return evaluateFunction_indexOf(arguments);
			#end
			default:
				throw 'Unknown function: ${name}';
		}
	}

	static function evaluateFunction_length(arguments:Array<PrimitiveLiteral>):PrimitiveLiteral
	{
		if (arguments.length <= 0)
			throw 'Too few arguments for length(): ${arguments.length}';
		if (arguments.length >= 2)
			throw 'Too many arguments for length(): ${arguments.length}';

		var arg = arguments[0];

		switch (arg)
		{
			case NodelistLiteral(value):
				if (value.length == 1)
					return evaluateFunction_length([value[0]]);
				// return IntegerLiteral(value.length);
				return NothingLiteral;
			case StringLiteral(value):
				return IntegerLiteral(value.length);
			case ArrayLiteral(value):
				return IntegerLiteral(value.length);
			case ObjectLiteral(value):
				var keys = Reflect.fields(value);
				return IntegerLiteral(keys.length);
			case UndefinedLiteral:
				return NothingLiteral;
			default:
				return NothingLiteral;
		}
	}

	static function evaluateFunction_count(arguments:Array<PrimitiveLiteral>):PrimitiveLiteral
	{
		if (arguments.length <= 0)
			throw 'Too few arguments for count() (expected a single array): ${arguments.length}';
		if (arguments.length >= 2)
			throw 'Too many arguments for count() (expected a single array): ${arguments.length}';

		var arg = arguments[0];

		switch (arg)
		{
			case NodelistLiteral(value):
				return IntegerLiteral(value.length);
			default:
				return IntegerLiteral(0);
		}
	}

	static function evaluateFunction_match(arguments:Array<PrimitiveLiteral>):PrimitiveLiteral
	{
		if (arguments.length <= 1)
			throw 'Too few arguments for count() (expected a single array): ${arguments.length}';
		if (arguments.length >= 3)
			throw 'Too many arguments for count() (expected a single array): ${arguments.length}';

		var target = arguments[0];
		var pattern = arguments[1];

		switch (target)
		{
			case NodelistLiteral(value):
				if (value.length == 1)
					return evaluateFunction_match([value[0], pattern]);
				return BooleanLiteral(false);
			case StringLiteral(value):
				switch (pattern)
				{
					case NodelistLiteral(patternValue):
						if (patternValue.length == 1)
							return evaluateFunction_match([target, patternValue[0]]);
						return BooleanLiteral(false);
					case StringLiteral(patternValue):
						var regex = new EReg(patternValue, "g");
						if (!regex.match(value))
						{
							return BooleanLiteral(false);
						}

						// NOTE: ENTIRITY of string must match regular expression
						if (regex.matchedLeft() == "" && regex.matchedRight() == "")
							return BooleanLiteral(true);

						return BooleanLiteral(false);
					default:
						return BooleanLiteral(false);
				}
			default:
				return BooleanLiteral(false);
		}
	}

	static function evaluateFunction_search(arguments:Array<PrimitiveLiteral>):PrimitiveLiteral
	{
		if (arguments.length <= 1)
			throw 'Too few arguments for count() (expected a single array): ${arguments.length}';
		if (arguments.length >= 3)
			throw 'Too many arguments for count() (expected a single array): ${arguments.length}';

		var target = arguments[0];
		var pattern = arguments[1];

		switch (target)
		{
			case NodelistLiteral(value):
				if (value.length == 1)
					return evaluateFunction_search([value[0], pattern]);
				return BooleanLiteral(false);
			case StringLiteral(value):
				switch (pattern)
				{
					case NodelistLiteral(patternValue):
						if (patternValue.length == 1)
							return evaluateFunction_search([target, patternValue[0]]);
						return BooleanLiteral(false);
					case StringLiteral(patternValue):
						var regex = new EReg(patternValue, "g");
						// Allow for partial matches.
						var result = regex.match(value);

						return BooleanLiteral(result);
					default:
						return BooleanLiteral(false);
				}
			default:
				return BooleanLiteral(false);
		}
	}

	static function evaluateFunction_value(arguments:Array<PrimitiveLiteral>):PrimitiveLiteral
	{
		if (arguments.length <= 0)
			throw 'Too few arguments for value(): ${arguments.length}';
		if (arguments.length >= 2)
			throw 'Too many arguments for value(): ${arguments.length}';

		var arg = arguments[0];

		switch (arg)
		{
			case NodelistLiteral(value):
				if (value.length == 1)
				{
					return evaluateFunction_value([value[0]]);
				}
				else
				{
					// Empty nodelist or contains multiple nodes.
					return NothingLiteral;
				}
			case StringLiteral(value):
				return StringLiteral(value);
			case NumberLiteral(value):
				return NumberLiteral(value);
			case IntegerLiteral(value):
				return IntegerLiteral(value);
			case BooleanLiteral(value):
				return BooleanLiteral(value);
			case ObjectLiteral(value):
				return ObjectLiteral(value);
			case ArrayLiteral(value):
				return ArrayLiteral(value);
			case NullLiteral | UndefinedLiteral | NothingLiteral:
				return NothingLiteral;
		}
	}

	#if jsonpath_bonus
	static function evaluateFunction_indexOf(arguments:Array<PrimitiveLiteral>):PrimitiveLiteral {
		if (arguments.length <= 1)
			throw 'Too few arguments for indexOf(): ${arguments.length}';
		if (arguments.length >= 3)
			throw 'Too many arguments for indexOf(): ${arguments.length}';

		var list = arguments[0];
		var value = arguments[1];

		trace('indexOf(${list}, ${value})');

		switch (list)
		{
			case NodelistLiteral(list):
				if (list.length == 1)
					return evaluateFunction_indexOf([list[0], value]);
				return IntegerLiteral(-1);
			case ArrayLiteral(list):
				for (i in 0...list.length) {
					var listElement = PrimitiveLiteralTools.fromJSONData(list[i]);
					if (PrimitiveLiteralTools.compare(listElement, "==", value)) {
						return IntegerLiteral(i);
					}
				}
				return IntegerLiteral(-1);
			default:
				return NothingLiteral;
		}
	}
	#end
}
