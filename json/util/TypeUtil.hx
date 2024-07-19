package json.util;

class TypeUtil
{
	public static function isArray(input:Dynamic):Bool
	{
		return Std.isOfType(input, Array);
	}

	/**
	 * Returns true if the input is a JSON primative.
	 */
	public static function isPrimitive(input:Dynamic):Bool
	{
		switch (Type.typeof(input))
		{
			case TFloat, TInt: // Number
				return true;
			case TClass(c): // String
				if (Std.isOfType(input, String))
					return true;
			case TBool: // True or False
				return true;
			case TNull: // Null
				return true;
			default:
				return false;
		}
		return false;
	}

	public static function isFloat(input:Dynamic):Bool
	{
		switch (Type.typeof(input))
		{
			case TFloat:
				return true;
			default:
				return false;
		}
	}

	public static function isInt(input:Dynamic):Bool
	{
		switch (Type.typeof(input))
		{
			case TInt:
				return true;
			default:
				return false;
		}
	}

	public static function isBool(input:Dynamic):Bool
	{
		switch (Type.typeof(input))
		{
			case TBool:
				return true;
			default:
				return false;
		}
	}

	public static function isNull(input:Dynamic):Bool
	{
		switch (Type.typeof(input))
		{
			case TNull:
				return true;
			default:
				return false;
		}
	}

	public static function isString(input:Dynamic):Bool
	{
		return Std.isOfType(input, String);
	}
}
