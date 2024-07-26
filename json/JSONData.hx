package json;

import haxe.ds.Either;
import haxe.io.StringInput;
import json.path.JSONPath;
import json.util.TypeUtil;

/**
 * Wraps a JSON data structure in a `Map`-like interface,
 * with additional utilities for retrieving data from nested paths
 * and for handling array data.
 */
@:nullSafety
abstract JSONData(Dynamic) from Dynamic to Dynamic
{
	public static inline function build():JSONData
	{
		return buildObject();
	}

	public static inline function parse(input:String):JSONData
	{
		return haxe.Json.parse(~/(\r|\n|\t)/g.replace(input, ''));
	}

	public static inline function buildObject():JSONData
	{
		return {};
	}

	public static inline function buildArray():JSONData
	{
		return [];
	}

	/**
	 * Returns a value by specified `key`.
	 * Can be used like `jsonData["key"]`
	 * @return The value, or the defualt if the key is not present.
	 *   Can return `null` if the value was present but null.
	 */
	@:arrayAccess
	public inline function get(key:String, ?defaultValue:Dynamic):Null<Dynamic>
	{
		if (!exists(key)) return defaultValue;
		#if js
		var result = untyped this[key]; // we know it's an object, so we don't need a check
		#else
		var result = isObject() ? get_obj(key) : get_arr(key);
		#end
		return result;
	}

	inline function get_obj(key:String):Null<Dynamic>
	{
		return Reflect.field(this, key);
	}

	inline function get_arr(key:String):Null<Dynamic>
	{
		// Only numeric keys are allowed in arrays
		var index:Null<Int> = Std.parseInt(key);
		if (index == null)
			return null;

		return this[index];
	}

	/**
	 * Returns a value as `JSONData`.
	 */
	public inline function getData(key:String):Null<JSONData>
	{
		return get(key);
	}

	function getDataByPart(part:PathPart):Null<JSONData> {
		switch (part) {
			case Left(v):
				if (isArray()) {
					// Strings that aren't parsed as numbers are invalid
					throw 'get(): bad array index: ${v}';
				} else {
					return get(v);
				}
			case Right(v):
				return this[v];
		}
	}

	/**
	 * Get an element of the JSON data by a normalized JSONPath.
	 * If you want to perform a query using an actual JSONPath, use `JSONPath.query()` instead.
	 */
	public function getByPath(path:String):Null<Dynamic>
	{
		var pathParts:PathParts = JSONPath.splitNormalizedPath(path);
		return getByPathParts(pathParts);
	}

	function getByPathParts(pathParts:PathParts):Null<Dynamic>
	{
		if (pathParts.length == 0)
			return this;
		
		var element = getDataByPart(pathParts[0]);
		if (element == null)
		{
			if (pathParts.length == 1)
				return element;
			throw 'K:/${pathParts[0]}';
		}
		try
		{
			return element.getByPathParts(pathParts.slice(1));
		}
		catch (e)
		{
			throw 'K:/${pathParts[0]}${'$e'.substr(1)}';
		}
	}

	/**
	 * Set an element of the JSON data by a normalized JSONPath.
	 */
	public inline function setByPath(path:String, value:Dynamic):Dynamic
	{
		var pathParts = JSONPath.splitNormalizedPath(path);
		try
		{
			return setByPathParts(pathParts, value);
		}
		catch (e)
		{
			var firstChar = '$e'.charAt(0);
			switch (firstChar)
			{
				case "K":
					var path = '$e'.substr(2);
					throw 'path $path does not exist';
				default:
					throw e;
			}
		}
	}

	inline function setByPathParts(pathParts:PathParts, value:Dynamic):Dynamic
	{
		if (pathParts.length == 0) return (this = value);

		if (pathParts.length == 1)
		{
			return setDataByPart(pathParts[0], value);
		}

		var element = getDataByPart(pathParts[0]);
		if (element == null)
		{
			throw 'K:/${pathParts[0]}';
		}
		try
		{
			return element.setByPathParts(pathParts.slice(1), value);
		}
		catch (e)
		{
			throw 'K:/${pathParts[0]}${'$e'.substr(2)}';
		}
	}

	/**
	 * Sets a `value` for a specified `key`.
	 * Can be used like `jsonData["key"] = value`
	 * @return The value provided, or `null` if the key is not present.
	 */
	@:arrayAccess
	public inline function set(key:String, value:Dynamic):Dynamic
	{
		#if js
		return untyped this[key] = value;
		#else
		return isObject() ? set_obj(key, value) : set_arr(key, value);
		#end
	}

	inline function set_obj(key:String, value:Dynamic):Dynamic
	{
		Reflect.setField(this, key, value);
		return value;
	}

	inline function set_arr(key:String, value:Dynamic):Dynamic
	{
		// Only numeric keys are allowed in arrays
		var index:Null<Int> = Std.parseInt(key);
		if (index == null)
			throw 'Could not parse array index ${key}';

		this[index] = value;
		return value;
	}

	function setDataByPart(part:PathPart, value:Dynamic):Dynamic
	{
		switch (part) {
			case Left(v):
				if (isArray()) {
					// Strings that aren't parsed as numbers are invalid
					throw 'set(): bad array index: ${v}';
				} else {
					return set(v, value);
				}
			case Right(v):
				return this[v] = value;
		}
	}

	public inline function insert(key:String, value:Dynamic, strict:Bool = false):Dynamic
	{
		if (this == null) this = [];
		return isObject() ? insert_obj(key, value) : insert_arr(key, value, strict);
	}

	inline function insert_obj(key:String, value:Dynamic):Dynamic
	{
		return set_obj(key, value);
	}

	inline function insert_arr(key:String, value:Dynamic, strict:Bool = false):Dynamic
	{
		// Only numeric keys are allowed in arrays
		var index:Null<Int> = Std.parseInt(key);
		if (index == null) {
			if (key == '-') {
				// See RFC 6901
				
				this.insert(this.length, value);
				return value;
			} else {
				throw 'Could not parse array index ${key}';
			}
		} else {
			if (strict && (index < 0)) {
				throw 'Array index $index is out of bounds';
			} else if (strict && (index >= this.length+1)) {
				throw 'Array index $index is out of bounds';
			}

			this.insert(index, value);
			return value;
		}
	}

	inline function insertByPart(part:PathPart, value:Dynamic, strict:Bool = false):Dynamic
	{
		switch (part) {
			case Left(v):
				if (isArray()) {
					// See RFC 6901
					if (v == '-') {
						return insert_arr('-', value, strict);
					} else {
						// Strings that aren't parsed as numbers are invalid
						throw 'insert(): bad array index: ${v}';
					}
				} else {
					return insert(v, value, strict);
				}
			case Right(v):
				return insert('$v', value, strict);
		}
	}

	/**
	 * Insert an element into the JSON object/array by a normalized JSONPath.
	 */
	public inline function insertByPath(path:String, value:Dynamic, strict:Bool = false):Dynamic
	{
		var pathParts:PathParts = JSONPath.splitNormalizedPath(path);
		try
		{
			return insertByPathParts(pathParts, value, strict);
		}
		catch (e)
		{
			var firstChar = '$e'.charAt(0);
			switch (firstChar)
			{
				case "K":
					var path = '$e'.substr(2);
					throw 'path $path does not exist';
				default:
					throw e;
			}
		}
	}

	inline function insertByPathParts(pathParts:PathParts, value:Dynamic, strict:Bool = false):Dynamic
	{
		if (pathParts.length == 0) return (this = value);

		if (pathParts.length == 1)
		{
			return insertByPart(pathParts[0], value, strict);
		}

		var element = getDataByPart(pathParts[0]);
		if (element == null)
		{
			throw 'K:/${pathParts[0]}';
		}
		try
		{
			return element.insertByPathParts(pathParts.slice(1), value, strict);
		}
		catch (e)
		{
			// throw 'K:/${pathParts[0]}${'$e'.substr(2)}';
			throw e;
		}
	}

	/**
	 * Tells if the data contains a specified `key`.
	 * @return `true` if the key is present, `false` otherwise.
	 */
	public inline function exists(key:String):Bool
	{
		return isObject() ? exists_obj(key) : exists_arr(key);
	}

	inline function exists_obj(key:String):Bool
	{
		return Reflect.hasField(this, key);
	}

	inline function exists_arr(key:String):Bool
	{
		// Only numeric keys are allowed in arrays
		var index:Null<Int> = Std.parseInt(key);
		if (index == null) {
			trace('exists_arr: ${key}');
			throw 'Could not parse array index ${key}';
		}

		// Simply check the length.
		// If we check if the value is non-null, we get a false negative if the array CONTAINS nulls.
		return this.length > index;
	}

	function existsByPart(part:PathPart):Bool
	{
		switch (part) {
			case Left(v):
				if (isArray()) {
					// Strings that aren't parsed as numbers are invalid
					throw 'exists(): bad array index: ${v}';
				} else {
					return exists(v);
				}
			case Right(v):
				return exists('$v');
		}
	}

	/**
	 * Query existance of an element of the JSON data by a normalized JSONPath.
	 */
	public function existsByPath(path:String):Dynamic
	{
		var pathParts:PathParts = JSONPath.splitNormalizedPath(path);
		return existsByPathParts(pathParts);
	}

	function existsByPathParts(pathParts:PathParts):Dynamic
	{
		if (pathParts.length == 0)
			throw 'No path provided';
		if (pathParts.length == 1) {
			return existsByPart(pathParts[0]);
		}

		if (!existsByPart(pathParts[0])) {
			return false;
		}
		var element = getDataByPart(pathParts[0]);
		return element.existsByPathParts(pathParts.slice(1));
	}

	/**
	 * Removes a specified `key` in the data.
	 * @return `true` if `key` was present in structure, or `false` otherwise.
	 */
	public inline function remove(key:String):Bool
	{
		return isObject() ? remove_obj(key) : remove_arr(key);
	}

	inline function remove_obj(key:String):Bool
	{
		return Reflect.deleteField(this, key);
	}

	inline function remove_arr(key:String):Bool
	{
		// Only numeric keys are allowed in arrays
		var index:Null<Int> = Std.parseInt(key);
		if (index == null)
			return false;

		var target = get_arr(key);
		if (target == null)
			return false;

		return this.remove(target);
	}

	function removeDataByPart(part:PathPart):Dynamic {
		switch (part) {
			case Left(v):
				if (isArray()) {
					// Strings that aren't parsed as numbers are invalid
					throw 'remove(): bad array index: ${v}';
				} else {
					return remove(v);
				}
			case Right(v):
				return remove('$v');
			default:
				throw 'bad path part: ${part}';
		}
	}

	/**
	 * Remove an element of the JSON data by a normalized JSONPath.
	 */
	public function removeByPath(path:String):Dynamic
	{
		var pathParts:PathParts = JSONPath.splitNormalizedPath(path);
		return removeByPathParts(pathParts);
	}

	function removeByPathParts(pathParts:PathParts):Dynamic
	{
		if (pathParts.length == 0)
			throw 'No path provided';
		if (pathParts.length == 1)
			return removeDataByPart(pathParts[0]);

		var element = getDataByPart(pathParts[0]);
		if (element == null)
		{
			throw 'Key not found: ' + pathParts[0];
		}
		return element.removeByPathParts(pathParts.slice(1));
	}

	/**
	 * Returns an array of `keys` in the data.
	 */
	public inline function keys():Array<String>
	{
		if (isPrimitive())
			return [];
		return isObject() ? keys_obj() : keys_arr();
	}

	inline function keys_obj():Array<String>
	{
		return Reflect.fields(this);
	}

	inline function keys_arr():Array<String>
	{
		return [for (i in 0...this.length) Std.string(i)];
	}

	public inline function length():Int
	{
		return isObject() ? keys_obj().length : this.length;
	}

	public inline function isPrimitive():Bool
	{
		return TypeUtil.isPrimitive(this);
	}

	/**
		Returns a shallow copy of the structure
	**/
	public inline function copy():Null<JSONData>
	{
		return isObject() ? copy_obj() : copy_arr();
	}

	inline function copy_obj():Null<JSONData>
	{
		return Reflect.copy(this);
	}

	inline function copy_arr():Null<JSONData>
	{
		return this.copy();
	}

	/**
	 * @return `true` if this JSON is an array, `false` if it is an object
	 */
	public inline function isArray():Bool
	{
		return TypeUtil.isArray(this);
	}

	/**
	 * @return `true` if this JSON is an object, `false` if it is an array
	 */
	public inline function isObject():Bool
	{
		return !TypeUtil.isArray(this);
	}
}

typedef PathPart = Either<String, Int>;
typedef PathParts = Array<PathPart>;