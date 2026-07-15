package json;

import json.path.JSONPath;
import json.path.JSONPath.PathPart;
import json.path.JSONPath.PathParts;
import json.util.TypeUtil;
#if js
import js.Syntax;
#end

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
		return untyped this[key];
		#else
		return isObject() ? get_obj(key) : get_arr(key);
		#end
	}

	#if !js
	inline function get_obj(key:String):Null<Dynamic>
	{
		return Reflect.field(this, key);
	}

	inline function get_arr(key:String):Null<Dynamic>
	{
		var index:Null<Int> = Std.parseInt(key);
		if (index == null) return null;
		return this[index];
	}
	#end

	/**
	 * Returns a value as `JSONData`.
	 */
	public inline function getData(key:String):Null<JSONData>
	{
		return get(key);
	}

	function getDataByPart(part:PathPart):Null<JSONData>
	{
		if (part.isString()) {
			if (isArray()) {
				throw 'get(): bad array index: ${part.toString()}';
			} else {
				return get(part.toString());
			}
		} else {
			return this[part.toInt()];
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

			throw 'K:/${pathParts[0].toString()}';
		}
		try
		{
			return element.getByPathParts(pathParts.slice(1));
		}
		catch (e)
		{
			throw '[/${pathParts[0].toString()}] ${'$e'}';
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

	#if !js
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
	#end

	function setDataByPart(part:PathPart, value:Dynamic):Dynamic
	{
		if (part.isString()) {
			if (isArray()) {
				// This is an array, so we should set by index,
				// but we got a string! That's not allowed.
				throw 'set(): bad array index: ${part.toString()}';
			} else {
				return set(part.toString(), value);
			}
		} else {
			return this[part.toInt()] = value;
		}
	}

	public inline function insert(key:String, value:Dynamic, strict:Bool = false):Dynamic
	{
		if (this == null) this = [];
		return isObject() ? insert_obj(key, value) : insert_arr(key, value, strict);
	}

	inline function insert_obj(key:String, value:Dynamic):Dynamic
	{
		#if js
		untyped this[key] = value;
		return value;
		#else
		return set_obj(key, value);
		#end
	}

	inline function insert_arr(key:String, value:Dynamic, strict:Bool = false):Dynamic
	{
		var index:Null<Int> = Std.parseInt(key);
		if (index == null) {
			if (key == '-') {
				#if js
				untyped this.push(value);
				#else
				this.insert(this.length, value);
				#end
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
			#if js
			untyped this.splice(index, 0, value);
			#else
			this.insert(index, value);
			#end
			return value;
		}
	}

	inline function insertByPart(part:PathPart, value:Dynamic, strict:Bool = false):Dynamic
	{
		if (part.isString()) {
			if (isArray()) {
				if (part.toString() == '-') {
					return insert_arr('-', value, strict);
				} else {
					// This is an array, so we should insert by index,
					// but we got a string! That's not allowed.
					throw 'insert(): bad array index: ${part.toString()}';
				}
			} else {
				return insert(part.toString(), value, strict);
			}
		} else {
			return insert(part.toString(), value, strict);
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
			throw e;
		}
	}

	/**
	 * Tells if the data contains a specified `key`.
	 * @return `true` if the key is present, `false` otherwise.
	 */
	public inline function exists(key:String):Bool
	{
		#if js
		if (isArray()) {
			var index:Null<Int> = Std.parseInt(key);
			if (index == null) {
				trace('exists_arr: ${key}');
				throw 'Could not parse array index ${key}';
			}
			return untyped this.length > index;
		} else {
			return untyped this.hasOwnProperty(key);
		}
		#else
		return isObject() ? exists_obj(key) : exists_arr(key);
		#end
	}

	#if !js
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
	#end

	function existsByPart(part:PathPart):Bool
	{
		if (part.isString()) {
			if (isArray()) {
				// This is an array, so we should query by index,
				// but we got a string! That's not allowed.
				throw 'exists(): bad array index: ${part.toString()}';
			} else {
				return exists(part.toString());
			}
		} else {
			return exists(part.toString());
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
		#if js
		if (isArray()) {
			var index:Null<Int> = Std.parseInt(key);
			if (index == null) return false;
			if (untyped this.length <= index) return false;
			untyped this.splice(index, 1);
			return true;
		} else {
			if (!untyped this.hasOwnProperty(key)) return false;
			js.Syntax.code('delete {0}[{1}]', this, key);
			return true;
		}
		#else
		return isObject() ? remove_obj(key) : remove_arr(key);
		#end
	}

	#if !js
	inline function remove_obj(key:String):Bool
	{
		return Reflect.deleteField(this, key);
	}

	inline function remove_arr(key:String):Bool
	{
		// Only numeric keys are allowed in arrays
		var index:Null<Int> = Std.parseInt(key);
		if (index == null) return false;
		if (this.length <= index) return false;
		this.splice(index, 1);
		return true;
	}
	#end

	function removeDataByPart(part:PathPart):Dynamic
	{
		if (part.isString()) {
			if (isArray()) {
				// This is an array, so we should remove by index,
				// but we got a string! That's not allowed.
				throw 'remove(): bad array index: ${part.toString()}';
			} else {
				return remove(part.toString());
			}
		} else {
			return remove(part.toString());
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
		#if js
		if (isArray()) {
			var len:Int = untyped this.length;
			return [for (i in 0...len) Std.string(i)];
		} else {
			return untyped Object.keys(this);
		}
		#else
		return isObject() ? keys_obj() : keys_arr();
		#end
	}

	#if !js
	inline function keys_obj():Array<String>
	{
		return Reflect.fields(this);
	}

	inline function keys_arr():Array<String>
	{
		return [for (i in 0...this.length) Std.string(i)];
	}
	#end

	public inline function length():Int
	{
		#if js
		return isArray() ? untyped this.length : untyped Object.keys(this).length;
		#else
		return isObject() ? keys_obj().length : this.length;
		#end
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
		#if js
		if (isArray()) {
			return untyped this.slice(0);
		} else {
			return untyped Object.assign({}, this);
		}
		#else
		return isObject() ? copy_obj() : copy_arr();
		#end
	}

	#if !js
	inline function copy_obj():Null<JSONData>
	{
		return Reflect.copy(this);
	}

	inline function copy_arr():Null<JSONData>
	{
		return this.copy();
	}
	#end

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