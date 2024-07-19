package json.path;

import json.util.TypeUtil;

enum PrimitiveLiteral {
    ObjectLiteral(value:Dynamic);
    ArrayLiteral(value:Array<Dynamic>);

    StringLiteral(value:String);
    NumberLiteral(value:Float);
    IntegerLiteral(value:Int);
    BoolLiteral(value:Bool);
    NullLiteral;
}

class PrimitiveLiteralTools {
    public static function fromJSONData(data:JSONData):PrimitiveLiteral {
        if (data.isPrimitive()) {
            if (TypeUtil.isString(data)) {
                return PrimitiveLiteral.StringLiteral(data);
            } else if (TypeUtil.isFloat(data)) {
                return PrimitiveLiteral.NumberLiteral(data);
            } else if (TypeUtil.isInt(data)) {
                return PrimitiveLiteral.IntegerLiteral(data);
            } else if (TypeUtil.isBool(data)) {
                return PrimitiveLiteral.BoolLiteral(data);
            } else if (TypeUtil.isNull(data)) {
                return PrimitiveLiteral.NullLiteral;
            } else {
                throw 'Unknown data type';
            }
        } else if (data.isObject()) {
            return PrimitiveLiteral.ObjectLiteral(data);
        } else if (data.isArray()) {
            return PrimitiveLiteral.ArrayLiteral(data);
        } else {
            throw 'Unknown data type';
        }

        return PrimitiveLiteral.NullLiteral;
    }

    public static function compare(left:PrimitiveLiteral, op:String, right:PrimitiveLiteral):Bool {
        switch (op) {
            case '==':
                return compare_Equals(left, right);
            case '!=':
                return compare_NotEquals(left, right);
            case '<':
                return compare_LessThan(left, right);
            case '<=':
                return compare_LessThanEquals(left, right);
            case '>':
                return compare_GreaterThan(left, right);
            case '>=':
                return compare_GreaterThanEquals(left, right);
            default:
                throw 'Unknown operator $op';
        }
    }
    
    static function compare_Equals(left:PrimitiveLiteral, right:PrimitiveLiteral):Bool {
        switch (left) {
            case NullLiteral:
                switch(right) {
                    case NullLiteral:
                        // null == null
                        return true;
                    default:
                        // Nulls always return false when compared
                        return false;
                }
            case ArrayLiteral(valueL):
                switch(right) {
                    case ArrayLiteral(valueR):
                        // Array equality.
                        return thx.Arrays.equals(valueL, valueR);
                    default:
                        // Type mismatch
                        return false;
                }
            case ObjectLiteral(valueL):
                switch(right) {
                    case ObjectLiteral(valueR):
                        // Object equality.
                        return thx.Dynamics.equals(valueL, valueR);
                    default:
                        // Type mismatch
                        return false;
                }
            case StringLiteral(valueL):
                switch(right) {
                    case StringLiteral(valueR):
                        return valueL == valueR;
                    case NumberLiteral(_) | IntegerLiteral(_) | BoolLiteral(_):
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                }
            case NumberLiteral(valueL):
                switch(right) {
                    case NumberLiteral(valueR):
                        return valueL == valueR;
                    case IntegerLiteral(valueR):
                        return valueL == valueR;
                    case BoolLiteral(_) | StringLiteral(_):
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                }
            case IntegerLiteral(valueL):
                switch(right) {
                    case NumberLiteral(valueR):
                        return valueL == valueR;
                    case IntegerLiteral(valueR):
                        return valueL == valueR;
                    case StringLiteral(_) | BoolLiteral(_):
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                }
            case BoolLiteral(valueL):
                switch(right) {
                    case BoolLiteral(valueR):
                        return valueL == valueR;
                    case StringLiteral(_) | NumberLiteral(_) | IntegerLiteral(_):
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                }        
        }
    }


    static function compare_LessThan(left:PrimitiveLiteral, right:PrimitiveLiteral):Bool {
        switch (left) {
            case ObjectLiteral(_) | ArrayLiteral(_):
                // Objects/arrays do not offer < comparison
                return false;
            case BoolLiteral(_):
                // Booleans do not offer < comparison
                return false;
            case NullLiteral:
                // Nulls always return false when compared
                return false;
            case NumberLiteral(valueL):
                switch(right) {
                    case NumberLiteral(valueR):
                        return valueL < valueR;
                    case IntegerLiteral(valueR):
                        return valueL < valueR;
                    case StringLiteral(_):
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Objects/arrays do not offer < comparison
                        return false;
                    case BoolLiteral(_):
                        // Booleans do not offer < comparison
                        return false;
                    case NullLiteral:
                        // Nulls always return false when compared
                        return false;
                }
            case IntegerLiteral(valueL):
                switch(right) {
                    case NumberLiteral(valueR):
                        return valueL < valueR;
                    case IntegerLiteral(valueR):
                        return valueL < valueR;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Objects/arrays do not offer < comparison
                        return false;
                    case StringLiteral(_):
                        // Type mismatch
                        return false;
                    case BoolLiteral(_):
                        // Booleans do not offer < comparison
                        return false;
                    case NullLiteral:
                        // Nulls always return false when compared
                        return false;
                }
            default:
                throw 'Unimplemented';
        }
    }


    static function compare_GreaterThan(left:PrimitiveLiteral, right:PrimitiveLiteral):Bool {
        switch (left) {
            case ObjectLiteral(_) | ArrayLiteral(_):
                // Objects/arrays do not offer > comparison
                return false;
            case BoolLiteral(_):
                // Booleans do not offer < comparison
                return false;
            case NullLiteral:
                // Nulls always return false when compared
                return false;
            case NumberLiteral(valueL):
                switch(right) {
                    case NumberLiteral(valueR):
                        return valueL > valueR;
                    case IntegerLiteral(valueR):
                        return valueL > valueR;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Objects/arrays do not offer > comparison
                        return false;
                    case StringLiteral(_):
                        // Type mismatch
                        return false;
                    case BoolLiteral(_):
                        // Booleans do not offer > comparison
                        return false;
                    case NullLiteral:
                        // Nulls always return false when compared
                        return false;
                }
            case IntegerLiteral(valueL):
                switch(right) {
                    case NumberLiteral(valueR):
                        return valueL > valueR;
                    case IntegerLiteral(valueR):
                        return valueL > valueR;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Objects/arrays do not offer > comparison
                        return false;
                    case StringLiteral(_):
                        // Type mismatch
                        return false;
                    case BoolLiteral(_):
                        // Booleans do not offer > comparison
                        return false;
                    case NullLiteral:
                        // Nulls always return false when compared
                        return false;
                }
            default:
                throw 'Unimplemented';
        }
    }

    static function compare_NotEquals(left:PrimitiveLiteral, right:PrimitiveLiteral):Bool {
        return !compare_Equals(left, right);
    }

    static function compare_LessThanEquals(left:PrimitiveLiteral, right:PrimitiveLiteral):Bool {
        return compare_LessThan(left, right) || compare_Equals(left, right);
    }

    static function compare_GreaterThanEquals(left:PrimitiveLiteral, right:PrimitiveLiteral):Bool {
        return compare_GreaterThan(left, right) || compare_Equals(left, right);
    }
}