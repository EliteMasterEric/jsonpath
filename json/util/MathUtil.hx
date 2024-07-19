package json.util;

class MathUtil {
    public static function clampi(value:Int, min:Int, max:Int):Int {
        if (value > max) return max;
        if (value < min) return min;
        return value;
    }
}