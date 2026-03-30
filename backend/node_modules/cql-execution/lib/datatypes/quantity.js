"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.doMultiplication = exports.doDivision = exports.doSubtraction = exports.doAddition = exports.parseQuantity = exports.Quantity = void 0;
const math_1 = require("../util/math");
const units_1 = require("../util/units");
class Quantity {
    constructor(value, unit) {
        this.value = value;
        this.unit = unit;
        if (this.value == null || isNaN(this.value)) {
            throw new Error('Cannot create a quantity with an undefined value');
        }
        else if (!(0, math_1.isValidDecimal)(this.value)) {
            throw new Error('Cannot create a quantity with an invalid decimal value');
        }
        // Attempt to parse the unit with UCUM. If it fails, throw a friendly error.
        if (this.unit != null) {
            const validation = (0, units_1.checkUnit)(this.unit);
            if (!validation.valid) {
                throw new Error(validation.message);
            }
        }
    }
    get isQuantity() {
        return true;
    }
    clone() {
        return new Quantity(this.value, this.unit);
    }
    toString() {
        return `${this.value} '${this.unit}'`;
    }
    sameOrBefore(other) {
        if (other != null && other.isQuantity) {
            const otherVal = (0, units_1.convertUnit)(other.value, other.unit, this.unit);
            if (otherVal == null) {
                return null;
            }
            else {
                return this.value <= otherVal;
            }
        }
    }
    sameOrAfter(other) {
        if (other != null && other.isQuantity) {
            const otherVal = (0, units_1.convertUnit)(other.value, other.unit, this.unit);
            if (otherVal == null) {
                return null;
            }
            else {
                return this.value >= otherVal;
            }
        }
    }
    after(other) {
        if (other != null && other.isQuantity) {
            const otherVal = (0, units_1.convertUnit)(other.value, other.unit, this.unit);
            if (otherVal == null) {
                return null;
            }
            else {
                return this.value > otherVal;
            }
        }
    }
    before(other) {
        if (other != null && other.isQuantity) {
            const otherVal = (0, units_1.convertUnit)(other.value, other.unit, this.unit);
            if (otherVal == null) {
                return null;
            }
            else {
                return this.value < otherVal;
            }
        }
    }
    equals(other) {
        if (other != null && other.isQuantity) {
            if ((!this.unit && other.unit) || (this.unit && !other.unit)) {
                return false;
            }
            else if (!this.unit && !other.unit) {
                return this.value === other.value;
            }
            else {
                const otherVal = (0, units_1.convertUnit)(other.value, other.unit, this.unit);
                if (otherVal == null) {
                    return null;
                }
                else {
                    return (0, math_1.decimalAdjust)('round', this.value, -8) === otherVal;
                }
            }
        }
    }
    convertUnit(toUnit) {
        const value = (0, units_1.convertUnit)(this.value, this.unit, toUnit);
        // Need to pass through constructor again to catch invalid units
        return new Quantity(value, toUnit);
    }
    dividedBy(other) {
        if (other == null || other === 0 || other.value === 0) {
            return null;
        }
        else if (!other.isQuantity) {
            // convert it to a quantity w/ unit 1
            other = new Quantity(other, '1');
        }
        const [val1, unit1, val2, unit2] = (0, units_1.normalizeUnitsWhenPossible)(this.value, this.unit, other.value, other.unit);
        const resultValue = val1 / val2;
        const resultUnit = (0, units_1.getQuotientOfUnits)(unit1, unit2);
        // Check for invalid unit or value
        if (resultUnit == null || (0, math_1.overflowsOrUnderflows)(resultValue)) {
            return null;
        }
        return new Quantity((0, math_1.decimalAdjust)('round', resultValue, -8), resultUnit);
    }
    multiplyBy(other) {
        if (other == null) {
            return null;
        }
        else if (!other.isQuantity) {
            // convert it to a quantity w/ unit 1
            other = new Quantity(other, '1');
        }
        const [val1, unit1, val2, unit2] = (0, units_1.normalizeUnitsWhenPossible)(this.value, this.unit, other.value, other.unit);
        const resultValue = val1 * val2;
        const resultUnit = (0, units_1.getProductOfUnits)(unit1, unit2);
        // Check for invalid unit or value
        if (resultUnit == null || (0, math_1.overflowsOrUnderflows)(resultValue)) {
            return null;
        }
        return new Quantity((0, math_1.decimalAdjust)('round', resultValue, -8), resultUnit);
    }
}
exports.Quantity = Quantity;
function parseQuantity(str) {
    const components = /([+|-]?\d+\.?\d*)\s*('(.+)')?/.exec(str);
    if (components != null && components[1] != null) {
        const value = parseFloat(components[1]);
        if (!(0, math_1.isValidDecimal)(value)) {
            return null;
        }
        let unit;
        if (components[3] != null) {
            unit = components[3].trim();
        }
        else {
            unit = '';
        }
        return new Quantity(value, unit);
    }
    else {
        return null;
    }
}
exports.parseQuantity = parseQuantity;
function doScaledAddition(a, b, scaleForB) {
    if (a != null && a.isQuantity && b != null && b.isQuantity) {
        const [val1, unit1, val2, unit2] = (0, units_1.normalizeUnitsWhenPossible)(a.value, a.unit, b.value * scaleForB, b.unit);
        if (unit1 !== unit2) {
            // not compatible units, so we can't do addition
            return null;
        }
        const sum = val1 + val2;
        if ((0, math_1.overflowsOrUnderflows)(sum)) {
            return null;
        }
        return new Quantity(sum, unit1);
    }
    else if (a.copy && a.add) {
        // Date / DateTime require a CQL time unit
        const cqlUnitB = (0, units_1.convertToCQLDateUnit)(b.unit) || b.unit;
        return a.copy().add(b.value * scaleForB, cqlUnitB);
    }
    else {
        throw new Error('Unsupported argument types.');
    }
}
function doAddition(a, b) {
    return doScaledAddition(a, b, 1);
}
exports.doAddition = doAddition;
function doSubtraction(a, b) {
    return doScaledAddition(a, b, -1);
}
exports.doSubtraction = doSubtraction;
function doDivision(a, b) {
    if (a != null && a.isQuantity) {
        return a.dividedBy(b);
    }
}
exports.doDivision = doDivision;
function doMultiplication(a, b) {
    if (a != null && a.isQuantity) {
        return a.multiplyBy(b);
    }
    else {
        return b.multiplyBy(a);
    }
}
exports.doMultiplication = doMultiplication;
//# sourceMappingURL=quantity.js.map