package json;

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
    public static inline function build():JSONData {
        return buildObject();
    }

    public static inline function parse(input:String):JSONData {
        return haxe.Json.parse(~/(\r|\n|\t)/g.replace(input, ''));
    }
    
    public static inline function buildObject():JSONData {
        return {};
    }

    public static inline function buildArray():JSONData {
        return [];
    }

	/**
	 * Returns a value by specified `key`.
     * Can be used like `jsonData["key"]`
	 * @return The value, or `null` if the key is not present.
	 */
	@:arrayAccess
	public inline function get(key:String, ?defaultValue:Dynamic):Null<Dynamic>
	{
        #if js
		var result = untyped this[key]; // we know it's an object, so we don't need a check
		#else
        var result = isObject() ? get_obj(key) : get_arr(key);
        #end
        if (result == null) return defaultValue;
        return result;
	}

    inline function get_obj(key:String):Null<Dynamic> {
		return Reflect.field(this, key);
    }

    inline function get_arr(key:String):Null<Dynamic> {
        // Only numeric keys are allowed in arrays
        var index:Null<Int> = Std.parseInt(key);
        if (index == null) return null;

        return this[index];
    }

	/**
	 * Returns a value as `JSONData`.
	 */
    public inline function getData(key:String):Null<JSONData>
    {
        return get(key);
    }

	/**
	 * Get an element of the JSON data by a normalized JSONPath.
     * If you want to perform a query using an actual JSONPath, use `JSONPath.query()` instead.
	 */
    public function getByPath(path:String):Null<Dynamic> {
        var pathParts = JSONPath.splitNormalizedPath(path);
        return getByPathParts(pathParts);
    }

    function getByPathParts(pathParts:Array<String>):Null<Dynamic> {
        if (pathParts.length == 0) return this;
        return getData(pathParts[0]).getByPathParts(pathParts.slice(1));
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

    inline function set_obj(key:String, value:Dynamic):Dynamic {
		Reflect.setField(this, key, value);
		return value;
    }

    inline function set_arr(key:String, value:Dynamic):Dynamic {
        // Only numeric keys are allowed in arrays
        var index:Null<Int> = Std.parseInt(key);
        if (index == null) return null;

        this[index] = value;
        return value;
    }

	/**
	 * Tells if the data contains a specified `key`.
	 * @return `true` if the key is present, `false` otherwise.
	 */
	public inline function exists(key:String):Bool
	{
		return isObject() ? exists_obj(key) : exists_arr(key);
	}

    inline function exists_obj(key:String):Bool {
        return Reflect.hasField(this, key);
    }

    inline function exists_arr(key:String):Bool {
        // Only numeric keys are allowed in arrays
        var index:Null<Int> = Std.parseInt(key);
        if (index == null) return false;

        // Simply check the length.
        // If we check if the value is non-null, we get a false negative if the array CONTAINS nulls.
        return this.length > index;
    }

	/**
	 * Removes a specified `key` in the data.
	 * @return `true` if `key` was present in structure, or `false` otherwise.
	 */
	public inline function remove(key:String):Bool
	{
        return isObject() ? remove_obj(key) : remove_arr(key);
	}

    inline function remove_obj(key:String):Bool {
        return Reflect.deleteField(this, key);
    }

    inline function remove_arr(key:String):Bool {
        // Only numeric keys are allowed in arrays
        var index:Null<Int> = Std.parseInt(key);
        if (index == null) return false;

        var target = get_arr(key);
        if (target == null) return false;

        return this.remove(target);
    }

	/**
	 * Returns an array of `keys` in the data.
	 */
	public inline function keys():Array<String>
	{
		return isObject() ? keys_obj() : keys_arr();
	}

    inline function keys_obj():Array<String> {
        return Reflect.fields(this);
    }

    inline function keys_arr():Array<String> {
        return [for (i in 0...this.length) Std.string(i)];
    }

    public inline function length():Int {
        return isObject() ? keys_obj().length : this.length;
    }

    public inline function isPrimitive():Bool {
        return TypeUtil.isPrimitive(this);
    }

	/**
		Returns a shallow copy of the structure
	**/
	public inline function copy():Null<JSONData> {
        return Reflect.copy(this);
    }

    /**
     * @return `true` if this JSON is an array, `false` if it is an object
     */
    public inline function isArray():Bool {
        return TypeUtil.isArray(this);
    }

    /**
     * @return `true` if this JSON is an object, `false` if it is an array
     */
    public inline function isObject():Bool {
        return !TypeUtil.isArray(this);
    }
}
