"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Repository = void 0;
const library_1 = require("../elm/library");
class Repository {
    constructor(data) {
        this.data = data;
        this.libraries = Array.from(Object.values(data));
    }
    resolve(path, version) {
        for (const lib of this.libraries) {
            if (lib.library && lib.library.identifier) {
                const { id, system, version: libraryVersion } = lib.library.identifier;
                const libraryUri = `${system}/${id}`;
                if (path === libraryUri || path === id) {
                    if (version) {
                        if (libraryVersion === version) {
                            return new library_1.Library(lib, this);
                        }
                    }
                    else {
                        return new library_1.Library(lib, this);
                    }
                }
            }
        }
    }
}
exports.Repository = Repository;
//# sourceMappingURL=repository.js.map