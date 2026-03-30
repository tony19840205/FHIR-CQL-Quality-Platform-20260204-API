"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ThreeValuedLogic = void 0;
class ThreeValuedLogic {
    static and(...val) {
        if (val.includes(false)) {
            return false;
        }
        else if (val.includes(null)) {
            return null;
        }
        else {
            return true;
        }
    }
    static or(...val) {
        if (val.includes(true)) {
            return true;
        }
        else if (val.includes(null)) {
            return null;
        }
        else {
            return false;
        }
    }
    static xor(...val) {
        if (val.includes(null)) {
            return null;
        }
        else {
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            return val.reduce((a, b) => (!a ^ !b) === 1);
        }
    }
    static not(val) {
        if (val != null) {
            return !val;
        }
        else {
            return null;
        }
    }
}
exports.ThreeValuedLogic = ThreeValuedLogic;
//# sourceMappingURL=logic.js.map