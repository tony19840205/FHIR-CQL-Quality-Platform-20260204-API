"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.build = void 0;
/* eslint-disable @typescript-eslint/ban-ts-comment */
const E = __importStar(require("./expressions"));
const util_1 = require("../util/util");
function build(json) {
    if (json == null) {
        return json;
    }
    if ((0, util_1.typeIsArray)(json)) {
        return json.map(child => build(child));
    }
    if (json.type === 'FunctionRef') {
        return new E.FunctionRef(json);
    }
    else if (json.type === 'Literal') {
        return E.Literal.from(json);
    }
    else if (functionExists(json.type)) {
        return constructByName(json.type, json);
    }
    else {
        return null;
    }
}
exports.build = build;
function functionExists(name) {
    // @ts-ignore
    return typeof E[name] === 'function';
}
function constructByName(name, json) {
    // @ts-ignore
    return new E[name](json);
}
//# sourceMappingURL=builder.js.map