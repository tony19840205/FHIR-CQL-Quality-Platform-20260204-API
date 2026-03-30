"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Ratio = void 0;
class Ratio {
    constructor(numerator, denominator) {
        this.numerator = numerator;
        this.denominator = denominator;
        if (numerator == null) {
            throw new Error('Cannot create a ratio with an undefined numerator');
        }
        if (denominator == null) {
            throw new Error('Cannot create a ratio with an undefined denominator');
        }
    }
    get isRatio() {
        return true;
    }
    clone() {
        return new Ratio(this.numerator.clone(), this.denominator.clone());
    }
    toString() {
        return `${this.numerator.toString()} : ${this.denominator.toString()}`;
    }
    equals(other) {
        if (other != null && other.isRatio) {
            const divided_this = this.numerator.dividedBy(this.denominator);
            const divided_other = other.numerator.dividedBy(other.denominator);
            return divided_this === null || divided_this === void 0 ? void 0 : divided_this.equals(divided_other);
        }
        else {
            return false;
        }
    }
    equivalent(other) {
        const equal = this.equals(other);
        return equal != null ? equal : false;
    }
}
exports.Ratio = Ratio;
//# sourceMappingURL=ratio.js.map