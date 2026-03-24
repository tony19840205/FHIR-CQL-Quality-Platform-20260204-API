"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.decimalOrNull = exports.decimalAdjust = exports.minValueForType = exports.minValueForInstance = exports.maxValueForType = exports.maxValueForInstance = exports.predecessor = exports.successor = exports.OverFlowException = exports.limitDecimalPrecision = exports.isValidDecimal = exports.isValidInteger = exports.overflowsOrUnderflows = exports.MAX_TIME_VALUE = exports.MIN_TIME_VALUE = exports.MAX_DATE_VALUE = exports.MIN_DATE_VALUE = exports.MAX_DATETIME_VALUE = exports.MIN_DATETIME_VALUE = exports.MIN_FLOAT_PRECISION_VALUE = exports.MIN_FLOAT_VALUE = exports.MAX_FLOAT_VALUE = exports.MIN_INT_VALUE = exports.MAX_INT_VALUE = void 0;
/* eslint-disable @typescript-eslint/no-loss-of-precision */
const exception_1 = require("../datatypes/exception");
const datetime_1 = require("../datatypes/datetime");
const uncertainty_1 = require("../datatypes/uncertainty");
exports.MAX_INT_VALUE = Math.pow(2, 31) - 1;
exports.MIN_INT_VALUE = Math.pow(-2, 31);
exports.MAX_FLOAT_VALUE = 99999999999999999999.99999999;
exports.MIN_FLOAT_VALUE = -99999999999999999999.99999999;
exports.MIN_FLOAT_PRECISION_VALUE = Math.pow(10, -8);
exports.MIN_DATETIME_VALUE = datetime_1.MIN_DATETIME_VALUE;
exports.MAX_DATETIME_VALUE = datetime_1.MAX_DATETIME_VALUE;
exports.MIN_DATE_VALUE = datetime_1.MIN_DATE_VALUE;
exports.MAX_DATE_VALUE = datetime_1.MAX_DATE_VALUE;
exports.MIN_TIME_VALUE = datetime_1.MIN_TIME_VALUE;
exports.MAX_TIME_VALUE = datetime_1.MAX_TIME_VALUE;
function overflowsOrUnderflows(value) {
    if (value == null) {
        return false;
    }
    if (value.isQuantity) {
        if (!isValidDecimal(value.value)) {
            return true;
        }
    }
    else if (value.isTime && value.isTime()) {
        if (value.after(exports.MAX_TIME_VALUE)) {
            return true;
        }
        if (value.before(exports.MIN_TIME_VALUE)) {
            return true;
        }
    }
    else if (value.isDateTime) {
        if (value.after(exports.MAX_DATETIME_VALUE)) {
            return true;
        }
        if (value.before(exports.MIN_DATETIME_VALUE)) {
            return true;
        }
    }
    else if (value.isDate) {
        if (value.after(exports.MAX_DATE_VALUE)) {
            return true;
        }
        if (value.before(exports.MIN_DATE_VALUE)) {
            return true;
        }
    }
    else if (Number.isInteger(value)) {
        if (!isValidInteger(value)) {
            return true;
        }
    }
    else if (value.isUncertainty) {
        return overflowsOrUnderflows(value.low) || overflowsOrUnderflows(value.high);
    }
    else {
        if (!isValidDecimal(value)) {
            return true;
        }
    }
    return false;
}
exports.overflowsOrUnderflows = overflowsOrUnderflows;
function isValidInteger(integer) {
    if (isNaN(integer)) {
        return false;
    }
    if (integer > exports.MAX_INT_VALUE) {
        return false;
    }
    if (integer < exports.MIN_INT_VALUE) {
        return false;
    }
    return true;
}
exports.isValidInteger = isValidInteger;
function isValidDecimal(decimal) {
    if (isNaN(decimal)) {
        return false;
    }
    if (decimal > exports.MAX_FLOAT_VALUE) {
        return false;
    }
    if (decimal < exports.MIN_FLOAT_VALUE) {
        return false;
    }
    return true;
}
exports.isValidDecimal = isValidDecimal;
function limitDecimalPrecision(decimal) {
    let decimalString = decimal.toString();
    // For decimals so large that they are represented in scientific notation, javascript has already limited
    // the decimal to its own constraints, so we can't determine the original precision.  Leave as-is unless
    // this becomes problematic, in which case we would need our own parseFloat.
    if (decimalString.indexOf('e') !== -1) {
        return decimal;
    }
    const splitDecimalString = decimalString.split('.');
    const decimalPoints = splitDecimalString[1];
    if (decimalPoints != null && decimalPoints.length > 8) {
        decimalString = splitDecimalString[0] + '.' + splitDecimalString[1].substring(0, 8);
    }
    return parseFloat(decimalString);
}
exports.limitDecimalPrecision = limitDecimalPrecision;
class OverFlowException extends exception_1.Exception {
}
exports.OverFlowException = OverFlowException;
function successor(val) {
    if (typeof val === 'number') {
        if (Number.isInteger(val)) {
            if (val >= exports.MAX_INT_VALUE) {
                throw new OverFlowException();
            }
            else {
                return val + 1;
            }
        }
        else {
            if (val >= exports.MAX_FLOAT_VALUE) {
                throw new OverFlowException();
            }
            else {
                return val + exports.MIN_FLOAT_PRECISION_VALUE;
            }
        }
    }
    else if (val && val.isTime && val.isTime()) {
        if (val.sameAs(exports.MAX_TIME_VALUE)) {
            throw new OverFlowException();
        }
        else {
            return val.successor();
        }
    }
    else if (val && val.isDateTime) {
        if (val.sameAs(exports.MAX_DATETIME_VALUE)) {
            throw new OverFlowException();
        }
        else {
            return val.successor();
        }
    }
    else if (val && val.isDate) {
        if (val.sameAs(exports.MAX_DATE_VALUE)) {
            throw new OverFlowException();
        }
        else {
            return val.successor();
        }
    }
    else if (val && val.isUncertainty) {
        // For uncertainties, if the high is the max val, don't increment it
        const high = (() => {
            try {
                return successor(val.high);
            }
            catch (e) {
                return val.high;
            }
        })();
        return new uncertainty_1.Uncertainty(successor(val.low), high);
    }
    else if (val && val.isQuantity) {
        const succ = val.clone();
        succ.value = successor(val.value);
        return succ;
    }
    else if (val == null) {
        return null;
    }
}
exports.successor = successor;
function predecessor(val) {
    if (typeof val === 'number') {
        if (Number.isInteger(val)) {
            if (val <= exports.MIN_INT_VALUE) {
                throw new OverFlowException();
            }
            else {
                return val - 1;
            }
        }
        else {
            if (val <= exports.MIN_FLOAT_VALUE) {
                throw new OverFlowException();
            }
            else {
                return val - exports.MIN_FLOAT_PRECISION_VALUE;
            }
        }
    }
    else if (val && val.isTime && val.isTime()) {
        if (val.sameAs(exports.MIN_TIME_VALUE)) {
            throw new OverFlowException();
        }
        else {
            return val.predecessor();
        }
    }
    else if (val && val.isDateTime) {
        if (val.sameAs(exports.MIN_DATETIME_VALUE)) {
            throw new OverFlowException();
        }
        else {
            return val.predecessor();
        }
    }
    else if (val && val.isDate) {
        if (val.sameAs(exports.MIN_DATE_VALUE)) {
            throw new OverFlowException();
        }
        else {
            return val.predecessor();
        }
    }
    else if (val && val.isUncertainty) {
        // For uncertainties, if the low is the min val, don't decrement it
        const low = (() => {
            try {
                return predecessor(val.low);
            }
            catch (e) {
                return val.low;
            }
        })();
        return new uncertainty_1.Uncertainty(low, predecessor(val.high));
    }
    else if (val && val.isQuantity) {
        const pred = val.clone();
        pred.value = predecessor(val.value);
        return pred;
    }
    else if (val == null) {
        return null;
    }
}
exports.predecessor = predecessor;
function maxValueForInstance(val) {
    if (typeof val === 'number') {
        if (Number.isInteger(val)) {
            return exports.MAX_INT_VALUE;
        }
        else {
            return exports.MAX_FLOAT_VALUE;
        }
    }
    else if (val && val.isTime && val.isTime()) {
        return exports.MAX_TIME_VALUE === null || exports.MAX_TIME_VALUE === void 0 ? void 0 : exports.MAX_TIME_VALUE.copy();
    }
    else if (val && val.isDateTime) {
        return exports.MAX_DATETIME_VALUE === null || exports.MAX_DATETIME_VALUE === void 0 ? void 0 : exports.MAX_DATETIME_VALUE.copy();
    }
    else if (val && val.isDate) {
        return exports.MAX_DATE_VALUE === null || exports.MAX_DATE_VALUE === void 0 ? void 0 : exports.MAX_DATE_VALUE.copy();
    }
    else if (val && val.isQuantity) {
        const val2 = val.clone();
        val2.value = maxValueForInstance(val2.value);
        return val2;
    }
    else {
        return null;
    }
}
exports.maxValueForInstance = maxValueForInstance;
function maxValueForType(type, quantityInstance) {
    switch (type) {
        case '{urn:hl7-org:elm-types:r1}Integer':
            return exports.MAX_INT_VALUE;
        case '{urn:hl7-org:elm-types:r1}Decimal':
            return exports.MAX_FLOAT_VALUE;
        case '{urn:hl7-org:elm-types:r1}DateTime':
            return exports.MAX_DATETIME_VALUE === null || exports.MAX_DATETIME_VALUE === void 0 ? void 0 : exports.MAX_DATETIME_VALUE.copy();
        case '{urn:hl7-org:elm-types:r1}Date':
            return exports.MAX_DATE_VALUE === null || exports.MAX_DATE_VALUE === void 0 ? void 0 : exports.MAX_DATE_VALUE.copy();
        case '{urn:hl7-org:elm-types:r1}Time':
            return exports.MAX_TIME_VALUE === null || exports.MAX_TIME_VALUE === void 0 ? void 0 : exports.MAX_TIME_VALUE.copy();
        case '{urn:hl7-org:elm-types:r1}Quantity': {
            if (quantityInstance == null) {
                // can't infer a quantity unit type from nothing]
                return null;
            }
            const maxQty = quantityInstance.clone();
            maxQty.value = maxValueForInstance(maxQty.value);
            return maxQty;
        }
    }
    return null;
}
exports.maxValueForType = maxValueForType;
function minValueForInstance(val) {
    if (typeof val === 'number') {
        if (Number.isInteger(val)) {
            return exports.MIN_INT_VALUE;
        }
        else {
            return exports.MIN_FLOAT_VALUE;
        }
    }
    else if (val && val.isTime && val.isTime()) {
        return exports.MIN_TIME_VALUE === null || exports.MIN_TIME_VALUE === void 0 ? void 0 : exports.MIN_TIME_VALUE.copy();
    }
    else if (val && val.isDateTime) {
        return exports.MIN_DATETIME_VALUE === null || exports.MIN_DATETIME_VALUE === void 0 ? void 0 : exports.MIN_DATETIME_VALUE.copy();
    }
    else if (val && val.isDate) {
        return exports.MIN_DATE_VALUE === null || exports.MIN_DATE_VALUE === void 0 ? void 0 : exports.MIN_DATE_VALUE.copy();
    }
    else if (val && val.isQuantity) {
        const val2 = val.clone();
        val2.value = minValueForInstance(val2.value);
        return val2;
    }
    else {
        return null;
    }
}
exports.minValueForInstance = minValueForInstance;
function minValueForType(type, quantityInstance) {
    switch (type) {
        case '{urn:hl7-org:elm-types:r1}Integer':
            return exports.MIN_INT_VALUE;
        case '{urn:hl7-org:elm-types:r1}Decimal':
            return exports.MIN_FLOAT_VALUE;
        case '{urn:hl7-org:elm-types:r1}DateTime':
            return exports.MIN_DATETIME_VALUE === null || exports.MIN_DATETIME_VALUE === void 0 ? void 0 : exports.MIN_DATETIME_VALUE.copy();
        case '{urn:hl7-org:elm-types:r1}Date':
            return exports.MIN_DATE_VALUE === null || exports.MIN_DATE_VALUE === void 0 ? void 0 : exports.MIN_DATE_VALUE.copy();
        case '{urn:hl7-org:elm-types:r1}Time':
            return exports.MIN_TIME_VALUE === null || exports.MIN_TIME_VALUE === void 0 ? void 0 : exports.MIN_TIME_VALUE.copy();
        case '{urn:hl7-org:elm-types:r1}Quantity': {
            if (quantityInstance == null) {
                // can't infer a quantity unit type from nothing]
                return null;
            }
            const minQty = quantityInstance.clone();
            minQty.value = minValueForInstance(minQty.value);
            return minQty;
        }
    }
    return null;
}
exports.minValueForType = minValueForType;
function decimalAdjust(type, value, exp) {
    //If the exp is undefined or zero...
    if (typeof exp === 'undefined' || +exp === 0) {
        return Math[type](value);
    }
    value = +value;
    exp = +exp;
    //If the value is not a number or the exp is not an integer...
    if (isNaN(value) || !(typeof exp === 'number' && exp % 1 === 0)) {
        return NaN;
    }
    //Shift
    value = value.toString().split('e');
    let v = value[1] ? +value[1] - exp : -exp;
    value = Math[type](+(value[0] + 'e' + v));
    //Shift back
    value = value.toString().split('e');
    v = value[1] ? +value[1] + exp : exp;
    return +(value[0] + 'e' + v);
}
exports.decimalAdjust = decimalAdjust;
function decimalOrNull(value) {
    return isValidDecimal(value) ? value : null;
}
exports.decimalOrNull = decimalOrNull;
//# sourceMappingURL=math.js.map