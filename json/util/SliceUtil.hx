package json.util;

class SliceUtil {
    /**
     * Return a slice of an array.
     * Select indices starting at the start, incrementing by step, and ending with end (exclusive).
     * 
     * @param input The target array.
     * @param start The starting index.
     * @param end The ending index.
     * @param step The amount to step by.
     */
    public static function slice<T>(input:Array<T>, ?start:Int, ?end:Int, ?step:Int):Array<T> {
        var indices = getSliceIndices(input.length, start, end, step);
        if (indices.length == 0) return [];

        return indices.map((index) -> input[index]);
    }

    public static function getSliceIndices(len:Int, ?start:Int, ?end:Int, step:Int = 1):Array<Int> {
        if (step == 0) return [];
        if (len == 0) return [];
        
        if (start == null) start = (step >= 0) ? 0 : (len - 1);
        // ERIC: Since `end` is exclusive, had to offset the >=0 case by 1 compared to the spec.
        if (end == null) end = (step >= 0) ? (len) : (-len - 1);
        
        // Normalize
        if (start < 0) start = len + start;
        if (end < 0) end = len + end;
        
        var lower:Int = (step >= 0) ? MathUtil.clampi(start, 0, len) : MathUtil.clampi(end, -1, len-1);
        var upper:Int = (step >= 0) ? MathUtil.clampi(end, 0, len) : MathUtil.clampi(start, -1, len-1);

        var result = [];
        if (step > 0) {
            if (step > len) {
                // Edge case: large positive step
                result.push(lower);
            } else {
                // Standard case: positive step
                var i = lower;
                while (i < upper) {
                    result.push(i);
                    i += step;
                }
            }
        } else if (step < 0) {
            if (step < -len) {
                // Edge case: large negative step
                result.push(upper);
            } else {
                // Standard case: negative step   
                var i = upper;
                while (lower < i) {
                    result.push(i);
                    i += step;
                }
            }
        }
        return result;
    }
}