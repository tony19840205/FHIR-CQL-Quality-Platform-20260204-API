import { Quantity } from './datatypes';
export declare class Ratio {
    numerator: Quantity;
    denominator: Quantity;
    constructor(numerator: Quantity, denominator: Quantity);
    get isRatio(): boolean;
    clone(): Ratio;
    toString(): string;
    equals(other: Ratio): boolean | null | undefined;
    equivalent(other: Ratio): boolean;
}
