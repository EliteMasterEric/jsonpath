package json.path;

import json.path.JSONPath.JSONNode;
import json.path.PrimitiveLiteral.PrimitiveLiteralTools;

/**
 * Node functions are not a part of the spec! It's a thing I made up.
 * They are functions which operate on a node rather than its value.
 */
class NodeFunctionExpression
{
	static final VALID_FUNCTIONS:Array<String> = ["name", "path"];

	public static function isValidNodeFunctionExpression(name:String):Bool
	{
        #if jsonpath_bonus
        return VALID_FUNCTIONS.indexOf(name) != -1;
        #else
        return false;
        #end
	}

	public static function evaluateNodeFunction(name:String, arguments:Array<JSONNode>):PrimitiveLiteral
	{
		switch (name)
		{
            #if jsonpath_bonus
			case "name":
				return evaluateFunction_name(arguments);
			case "path":
				return evaluateFunction_path(arguments);
			#end
			default:
				throw 'Unknown function: ${name}';
		}
	}

	#if jsonpath_bonus
	static function evaluateFunction_name(arguments:Array<JSONNode>):PrimitiveLiteral
	{
		if (arguments.length <= 0)
			throw 'Too few arguments for name(): ${arguments.length}';
		if (arguments.length >= 2)
			throw 'Too many arguments for name(): ${arguments.length}';

		var targetPath = arguments[0].path;

		return StringLiteral(targetPath);
	}

	static function evaluateFunction_path(arguments:Array<JSONNode>):PrimitiveLiteral
	{
		if (arguments.length <= 0)
			throw 'Too few arguments for path(): ${arguments.length}';
		if (arguments.length >= 2)
			throw 'Too many arguments for path(): ${arguments.length}';

		var targetPath = arguments[0].path;

		return StringLiteral(targetPath);
	}
	#end
}
