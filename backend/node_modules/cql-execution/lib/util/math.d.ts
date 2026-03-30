import { Exception } from '../datatypes/exception';
import { Quantity } from '../datatypes/quantity';
export declare const MAX_INT_VALUE: number;
export declare const MIN_INT_VALUE: number;
export declare const MAX_FLOAT_VALUE = 100000000000000000000;
export declare const MIN_FLOAT_VALUE = -100000000000000000000;
export declare const MIN_FLOAT_PRECISION_VALUE: number;
export declare const MIN_DATETIME_VALUE: import("../datatypes/datetime").DateTime | null;
export declare const MAX_DATETIME_VALUE: import("../datatypes/datetime").DateTime | null;
export declare const MIN_DATE_VALUE: import("../datatypes/datetime").Date | null;
export declare const MAX_DATE_VALUE: import("../datatypes/datetime").Date | null;
export declare const MIN_TIME_VALUE: import("../datatypes/datetime").DateTime | undefined;
export declare const MAX_TIME_VALUE: import("../datatypes/datetime").DateTime | undefined;
export declare function overflowsOrUnderflows(value: any): boolean;
export declare function isValidInteger(integer: any): boolean;
export declare function isValidDecimal(decimal: any): boolean;
export declare function limitDecimalPrecision(decimal: any): any;
export declare class OverFlowException extends Exception {
}
export declare function successor(val: any): any;
export declare function predecessor(val: any): any;
export declare function maxValueForInstance(val: any): any;
export declare function maxValueForType(type: string, quantityInstance?: Quantity): number | import("../datatypes/datetime").DateTime | import("../datatypes/datetime").Date | Quantity | null | undefined;
export declare function minValueForInstance(val: any): any;
export declare function minValueForType(type: string, quantityInstance?: Quantity): number | import("../datatypes/datetime").DateTime | import("../datatypes/datetime").Date | Quantity | null | undefined;
declare type MathFn = keyof typeof Math;
export declare function decimalAdjust(type: MathFn, value: any, exp: any): number;
export declare function decimalOrNull(value: any): any;
export {};
