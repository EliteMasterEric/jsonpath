package json.path;

import json.util.TypeUtil;

enum PrimitiveLiteral {
    StringLiteral(value:String);
    NumberLiteral(value:Float);
    IntegerLiteral(value:Int);
    BooleanLiteral(value:Bool);
    NullLiteral();

    ObjectLiteral(value:Dynamic);
    ArrayLiteral(value:Array<Dynamic>);
}

class PrimitiveLiteralTools {
    public static function fromJSONData(value:JSONData):PrimitiveLiteral {
        if (value.isPrimitive()) {
            if (TypeUtil.isString(value)) {
                return StringLiteral(value);
            } else if (TypeUtil.isFloat(value)) {
                return NumberLiteral(value);
            } else if (TypeUtil.isInt(value)) {
                return IntegerLiteral(value);
            } else if (TypeUtil.isBool(value)) {
                return BooleanLiteral(value);
            } else if (TypeUtil.isNull(value)) {
                return NullLiteral;
            } else {
                throw 'Could not parse ${value}';
            }
        } else if (value.isArray()) {
            return ArrayLiteral(value);
        } else if (value.isObject()) {
            return ObjectLiteral(value);
        } else {
            throw 'Could not parse ${value}';
        }
    }

    public static function compare(left: PrimitiveLiteral, op: String, right: PrimitiveLiteral): Bool {
        switch (op) {
            case "==":
                return compare_equal(left, right);
            case "!=":
                return compare_notEqual(left, right);
            case ">":
                return compare_greaterThan(left, right);
            case ">=":
                return compare_greaterThanOrEqual(left, right);
            case "<":
                return compare_lessThan(left, right);
            case "<=":
                return compare_lessThanOrEqual(left, right);
            default:
                throw 'Unknown comparison operator: ${op}';
        }
    }

    static function compare_equal(left: PrimitiveLiteral, right: PrimitiveLiteral): Bool {
        switch (left) {
            case ObjectLiteral(value):
                switch (right) {
                    case ObjectLiteral(rightValue):
                        return thx.Dynamics.equals(value, rightValue);
                    case ArrayLiteral(_) | StringLiteral(_) | NumberLiteral(_) | IntegerLiteral(_) | BooleanLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                }

            case ArrayLiteral(value):
                switch (right) {
                    case ArrayLiteral(rightValue):
                        return thx.Dynamics.equals(value, rightValue);
                    case ObjectLiteral(_) | StringLiteral(_) | NumberLiteral(_) | IntegerLiteral(_) | BooleanLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                }

            case StringLiteral(value):
                switch (right) {
                    case StringLiteral(rightValue):
                        return value == rightValue;
                    case NumberLiteral(_) | IntegerLiteral(_) | BooleanLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Type mismatch
                        return false;
                }
            case NumberLiteral(value):
                switch (right) {
                    case NumberLiteral(rightValue):
                        return value == rightValue;
                    case IntegerLiteral(rightValue):
                        return value == rightValue;

                    case StringLiteral(_) | BooleanLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Type mismatch
                        return false;
                }
            case IntegerLiteral(value):
                switch (right) {
                    case IntegerLiteral(rightValue):
                        return value == rightValue;
                    case NumberLiteral(rightValue):
                        return rightValue == value;
                    
                    case StringLiteral(_) | BooleanLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Type mismatch
                        return false;
                }
            case BooleanLiteral(value):
                switch (right) {
                    case BooleanLiteral(rightValue):
                        return value == rightValue;
                    case StringLiteral(_) | NumberLiteral(_) | IntegerLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Type mismatch
                        return false;
                }
            case NullLiteral:
                switch (right) {
                    case NullLiteral:
                        return true;
                    default:
                        return false;
                }
            default:
                return false;
        }
    }

    static function compare_greaterThan(left: PrimitiveLiteral, right: PrimitiveLiteral): Bool {
        switch (left) {
            case NumberLiteral(value):
                switch (right) {
                    case NumberLiteral(rightValue):
                        return value > rightValue;
                    case IntegerLiteral(rightValue):
                        return value > rightValue;
                    case StringLiteral(_) | BooleanLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Type mismatch
                        return false;
                }
            case IntegerLiteral(value):
                switch (right) {
                    case IntegerLiteral(rightValue):
                        return value > rightValue;
                    case NumberLiteral(rightValue):
                        return value > rightValue;
                    case StringLiteral(_) | BooleanLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Type mismatch
                        return false;
                }
            case StringLiteral(value):
                switch (right) {
                    case StringLiteral(rightValue):
                        return value > rightValue;
                    case NumberLiteral(_) | IntegerLiteral(_) | BooleanLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Type mismatch
                        return false;
                }
            case BooleanLiteral(_) | NullLiteral:
                // Unsupported operation
                return false;
            case ObjectLiteral(_) | ArrayLiteral(_):
                // Unsupported operation
                return false;
            default:
                return false;
        }
    }

    static function compare_lessThan(left: PrimitiveLiteral, right: PrimitiveLiteral): Bool {
        switch (left) {
            case NumberLiteral(value):
                switch (right) {
                    case NumberLiteral(rightValue):
                        return value < rightValue;
                    case IntegerLiteral(rightValue):
                        return value < rightValue;
                    case StringLiteral(_) | BooleanLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Type mismatch
                        return false;
                }
            case IntegerLiteral(value):
                switch (right) {
                    case IntegerLiteral(rightValue):
                        return value < rightValue;
                    case NumberLiteral(rightValue):
                        return value < rightValue;
                    case StringLiteral(_) | BooleanLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Type mismatch
                        return false;
                }
            case StringLiteral(value):
                switch (right) {
                    case StringLiteral(rightValue):
                        return value < rightValue;
                    case NumberLiteral(_) | IntegerLiteral(_) | BooleanLiteral(_) | NullLiteral:
                        // Type mismatch
                        return false;
                    case ObjectLiteral(_) | ArrayLiteral(_):
                        // Type mismatch
                        return false;
                }
            case BooleanLiteral(_) | NullLiteral:
                // Unsupported operation
                return false;
            case ObjectLiteral(_) | ArrayLiteral(_):
                // Unsupported operation
                return false;
            default:
                return false;
        }
    }

    static function compare_greaterThanOrEqual(left: PrimitiveLiteral, right: PrimitiveLiteral): Bool {
        return compare_greaterThan(left, right) || compare_equal(left, right);
    }

    static function compare_lessThanOrEqual(left: PrimitiveLiteral, right: PrimitiveLiteral): Bool {
        return compare_lessThan(left, right) || compare_equal(left, right);
    }

    static function compare_notEqual(left: PrimitiveLiteral, right: PrimitiveLiteral): Bool {
        return !compare_equal(left, right);
    }

}