package json.util;

import json.JSONData;

class ArrayUtil {
    /**
     * Return the list of items which are present in `list` but not in `subtract`.
     * TODO: There should be a `thx.core` function for this.
     * @param list The list of items
     * @param subtract The list of items to subtract
     * @return A list of items which are present in `list` but not in `subtract`.
     */
    public static function subtract<T>(list:Array<T>, subtract:Array<T>):Array<T> {
      return list.filter((item) -> {
        var contains = thx.Arrays.containsExact(subtract, item, thx.Dynamics.equals);
        return !contains;
      });
    }

  /**
   * Return true only if both arrays contain the same elements (possibly in a different order).
   * @param a The first array to compare.
   * @param b The second array to compare.
   * @return Weather both arrays contain the same elements.
   */
   public static function equalsUnordered<T>(a:Array<T>, b:Array<T>):Bool
    {
      if (a.length != b.length) return false;
      for (element in a)
      {
        if (!thx.Arrays.containsExact(b, element, thx.Dynamics.equals)) return false;
      }
      for (element in b)
      {
        if (!thx.Arrays.containsExact(a, element, thx.Dynamics.equals)) return false;
      }
      return true;
    }

    /**
     * Return the list of items which are present in both `list` and `intersect`.
     * @param list 
     * @param intersect 
     * @return
     */
    public static function intersect<T>(list:Array<T>, intersect:Array<T>):Array<T> {
      return list.filter((item) -> {
        var contains = thx.Arrays.containsExact(intersect, item, thx.Dynamics.equals);
        return contains;
      });
    }
}