/* @ts-self-types="./dart_automerge.d.ts" */

export class WorkerPool {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(WorkerPool.prototype);
        obj.__wbg_ptr = ptr;
        WorkerPoolFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        WorkerPoolFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_workerpool_free(ptr, 0);
    }
    /**
     * @param {number | null} [initial]
     * @param {string | null} [script_src]
     * @param {string | null} [worker_js_preamble]
     * @returns {WorkerPool}
     */
    static new(initial, script_src, worker_js_preamble) {
        var ptr0 = isLikeNone(script_src) ? 0 : passStringToWasm0(script_src, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        var len0 = WASM_VECTOR_LEN;
        var ptr1 = isLikeNone(worker_js_preamble) ? 0 : passStringToWasm0(worker_js_preamble, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        var len1 = WASM_VECTOR_LEN;
        const ret = wasm.workerpool_new(isLikeNone(initial) ? 0x100000001 : (initial) >>> 0, ptr0, len0, ptr1, len1);
        if (ret[2]) {
            throw takeFromExternrefTable0(ret[1]);
        }
        return WorkerPool.__wrap(ret[0]);
    }
    /**
     * Creates a new `WorkerPool` which immediately creates `initial` workers.
     *
     * The pool created here can be used over a long period of time, and it
     * will be initially primed with `initial` workers. Currently workers are
     * never released or gc'd until the whole pool is destroyed.
     *
     * # Errors
     *
     * Returns any error that may happen while a JS web worker is created and a
     * message is sent to it.
     * @param {number} initial
     * @param {string} script_src
     * @param {string} worker_js_preamble
     */
    constructor(initial, script_src, worker_js_preamble) {
        const ptr0 = passStringToWasm0(script_src, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(worker_js_preamble, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.workerpool_new_raw(initial, ptr0, len0, ptr1, len1);
        if (ret[2]) {
            throw takeFromExternrefTable0(ret[1]);
        }
        this.__wbg_ptr = ret[0] >>> 0;
        WorkerPoolFinalization.register(this, this.__wbg_ptr, this);
        return this;
    }
}
if (Symbol.dispose) WorkerPool.prototype[Symbol.dispose] = WorkerPool.prototype.free;

/**
 * @param {number} call_id
 * @param {any} ptr_
 * @param {number} rust_vec_len_
 * @param {number} data_len_
 */
export function frb_dart_fn_deliver_output(call_id, ptr_, rust_vec_len_, data_len_) {
    wasm.frb_dart_fn_deliver_output(call_id, ptr_, rust_vec_len_, data_len_);
}

/**
 * # Safety
 *
 * This should never be called manually.
 * @param {any} handle
 * @param {any} dart_handler_port
 * @returns {number}
 */
export function frb_dart_opaque_dart2rust_encode(handle, dart_handler_port) {
    const ret = wasm.frb_dart_opaque_dart2rust_encode(handle, dart_handler_port);
    return ret >>> 0;
}

/**
 * @param {number} ptr
 */
export function frb_dart_opaque_drop_thread_box_persistent_handle(ptr) {
    wasm.frb_dart_opaque_drop_thread_box_persistent_handle(ptr);
}

/**
 * @param {number} ptr
 * @returns {any}
 */
export function frb_dart_opaque_rust2dart_decode(ptr) {
    const ret = wasm.frb_dart_opaque_rust2dart_decode(ptr);
    return ret;
}

/**
 * @returns {number}
 */
export function frb_get_rust_content_hash() {
    const ret = wasm.frb_get_rust_content_hash();
    return ret;
}

/**
 * @param {number} func_id
 * @param {any} port_
 * @param {any} ptr_
 * @param {number} rust_vec_len_
 * @param {number} data_len_
 */
export function frb_pde_ffi_dispatcher_primary(func_id, port_, ptr_, rust_vec_len_, data_len_) {
    wasm.frb_pde_ffi_dispatcher_primary(func_id, port_, ptr_, rust_vec_len_, data_len_);
}

/**
 * @param {number} func_id
 * @param {any} ptr_
 * @param {number} rust_vec_len_
 * @param {number} data_len_
 * @returns {any}
 */
export function frb_pde_ffi_dispatcher_sync(func_id, ptr_, rust_vec_len_, data_len_) {
    const ret = wasm.frb_pde_ffi_dispatcher_sync(func_id, ptr_, rust_vec_len_, data_len_);
    return ret;
}

/**
 * ## Safety
 * This function reclaims a raw pointer created by [`TransferClosure`], and therefore
 * should **only** be used in conjunction with it.
 * Furthermore, the WASM module in the worker must have been initialized with the shared
 * memory from the host JS scope.
 * @param {number} payload
 * @param {any[]} transfer
 */
export function receive_transfer_closure(payload, transfer) {
    const ptr0 = passArrayJsValueToWasm0(transfer, wasm.__wbindgen_malloc);
    const len0 = WASM_VECTOR_LEN;
    const ret = wasm.receive_transfer_closure(payload, ptr0, len0);
    if (ret[1]) {
        throw takeFromExternrefTable0(ret[0]);
    }
}

/**
 * @param {number} ptr
 */
export function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerDocHandle(ptr) {
    wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerDocHandle(ptr);
}

/**
 * @param {number} ptr
 */
export function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSyncStateHandle(ptr) {
    wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSyncStateHandle(ptr);
}

/**
 * @param {number} ptr
 */
export function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerDocHandle(ptr) {
    wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerDocHandle(ptr);
}

/**
 * @param {number} ptr
 */
export function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSyncStateHandle(ptr) {
    wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSyncStateHandle(ptr);
}

export function wasm_start_callback() {
    wasm.wasm_start_callback();
}

function __wbg_get_imports() {
    const import0 = {
        __proto__: null,
        __wbg___wbindgen_debug_string_efb631f75e4a9f50: function(arg0, arg1) {
            const ret = debugString(arg1);
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg___wbindgen_is_falsy_7b2c59fe5ab79959: function(arg0) {
            const ret = !arg0;
            return ret;
        },
        __wbg___wbindgen_is_undefined_4125f6e839cf2c7e: function(arg0) {
            const ret = arg0 === undefined;
            return ret;
        },
        __wbg___wbindgen_jsval_eq_2399f5afc4caf128: function(arg0, arg1) {
            const ret = arg0 === arg1;
            return ret;
        },
        __wbg___wbindgen_memory_aec69791fcc899b8: function() {
            const ret = wasm.memory;
            return ret;
        },
        __wbg___wbindgen_module_57f6bc4bf7b0ad08: function() {
            const ret = wasmModule;
            return ret;
        },
        __wbg___wbindgen_number_get_91cf39c966f3690c: function(arg0, arg1) {
            const obj = arg1;
            const ret = typeof(obj) === 'number' ? obj : undefined;
            getDataViewMemory0().setFloat64(arg0 + 8 * 1, isLikeNone(ret) ? 0 : ret, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, !isLikeNone(ret), true);
        },
        __wbg___wbindgen_string_get_432068173ee8cef8: function(arg0, arg1) {
            const obj = arg1;
            const ret = typeof(obj) === 'string' ? obj : undefined;
            var ptr1 = isLikeNone(ret) ? 0 : passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            var len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg___wbindgen_throw_6ea4cf636881bef8: function(arg0, arg1) {
            throw new Error(getStringFromWasm0(arg0, arg1));
        },
        __wbg__wbg_cb_unref_83670fa1b4650226: function(arg0) {
            arg0._wbg_cb_unref();
        },
        __wbg_call_b7444c9acd8ea7bd: function() { return handleError(function (arg0, arg1) {
            const ret = arg0.call(arg1);
            return ret;
        }, arguments); },
        __wbg_createObjectURL_6c22efa4ff08b2ed: function() { return handleError(function (arg0, arg1) {
            const ret = URL.createObjectURL(arg1);
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        }, arguments); },
        __wbg_data_46b0651d3e4018ab: function(arg0) {
            const ret = arg0.data;
            return ret;
        },
        __wbg_error_076d4beefd7cfd14: function(arg0, arg1) {
            console.error(getStringFromWasm0(arg0, arg1));
        },
        __wbg_error_7534b8e9a36f1ab4: function(arg0, arg1) {
            let deferred0_0;
            let deferred0_1;
            try {
                deferred0_0 = arg0;
                deferred0_1 = arg1;
                console.error(getStringFromWasm0(arg0, arg1));
            } finally {
                wasm.__wbindgen_free(deferred0_0, deferred0_1, 1);
            }
        },
        __wbg_eval_745b0fa01376cffb: function() { return handleError(function (arg0, arg1) {
            const ret = eval(getStringFromWasm0(arg0, arg1));
            return ret;
        }, arguments); },
        __wbg_getRandomValues_1c61fac11405ffdc: function() { return handleError(function (arg0, arg1) {
            globalThis.crypto.getRandomValues(getArrayU8FromWasm0(arg0, arg1));
        }, arguments); },
        __wbg_get_b5c0d2cc90facf58: function() { return handleError(function (arg0, arg1) {
            const ret = Reflect.get(arg0, arg1);
            return ret;
        }, arguments); },
        __wbg_instanceof_BroadcastChannel_e5a20f6df0eec846: function(arg0) {
            let result;
            try {
                result = arg0 instanceof BroadcastChannel;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_instanceof_ErrorEvent_4c979c6a4efd8388: function(arg0) {
            let result;
            try {
                result = arg0 instanceof ErrorEvent;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_instanceof_MessageEvent_2dfa73dfa3f37765: function(arg0) {
            let result;
            try {
                result = arg0 instanceof MessageEvent;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_instanceof_MessagePort_de4506aa1fa5f893: function(arg0) {
            let result;
            try {
                result = arg0 instanceof MessagePort;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_length_184db1debc27a886: function(arg0) {
            const ret = arg0.length;
            return ret;
        },
        __wbg_log_026e3009324431bf: function(arg0, arg1) {
            console.log(getStringFromWasm0(arg0, arg1));
        },
        __wbg_message_79fc6413eaffc642: function(arg0, arg1) {
            const ret = arg1.message;
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg_name_05e8fbd130a3dc98: function(arg0, arg1) {
            const ret = arg1.name;
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg_new_33cce01013f488da: function() { return handleError(function (arg0, arg1) {
            const ret = new BroadcastChannel(getStringFromWasm0(arg0, arg1));
            return ret;
        }, arguments); },
        __wbg_new_67cbcbab9f40eb64: function() { return handleError(function (arg0, arg1) {
            const ret = new Worker(getStringFromWasm0(arg0, arg1));
            return ret;
        }, arguments); },
        __wbg_new_8a6f238a6ece86ea: function() {
            const ret = new Error();
            return ret;
        },
        __wbg_new_91c59c2641dcdb6b: function(arg0) {
            const ret = new Uint8Array(arg0);
            return ret;
        },
        __wbg_new_c390db0e7d29b395: function() {
            const ret = new Array();
            return ret;
        },
        __wbg_new_e207e22a7d1fce8c: function() {
            const ret = new Object();
            return ret;
        },
        __wbg_new_from_slice_c2e6cbc9992d53a2: function(arg0, arg1) {
            const ret = new Uint8Array(getArrayU8FromWasm0(arg0, arg1));
            return ret;
        },
        __wbg_new_no_args_55ca8a085badf696: function(arg0, arg1) {
            const ret = new Function(getStringFromWasm0(arg0, arg1));
            return ret;
        },
        __wbg_new_with_blob_sequence_and_options_616ce6bb19e2536a: function() { return handleError(function (arg0, arg1) {
            const ret = new Blob(arg0, arg1);
            return ret;
        }, arguments); },
        __wbg_postMessage_33814d4dc32c2dcf: function() { return handleError(function (arg0, arg1) {
            arg0.postMessage(arg1);
        }, arguments); },
        __wbg_postMessage_7b4a9f37f64ea797: function() { return handleError(function (arg0, arg1) {
            arg0.postMessage(arg1);
        }, arguments); },
        __wbg_postMessage_abff6f0f58d40bee: function() { return handleError(function (arg0, arg1) {
            arg0.postMessage(arg1);
        }, arguments); },
        __wbg_postMessage_e775fad1aef58e6f: function() { return handleError(function (arg0, arg1, arg2) {
            arg0.postMessage(arg1, arg2);
        }, arguments); },
        __wbg_prototypesetcall_26502571be737e08: function(arg0, arg1, arg2) {
            Uint8Array.prototype.set.call(getArrayU8FromWasm0(arg0, arg1), arg2);
        },
        __wbg_push_f97da1bff0343d3c: function(arg0, arg1) {
            const ret = arg0.push(arg1);
            return ret;
        },
        __wbg_set_81ca05aa4f293e0d: function() { return handleError(function (arg0, arg1, arg2) {
            const ret = Reflect.set(arg0, arg1, arg2);
            return ret;
        }, arguments); },
        __wbg_set_onerror_16cf034a579c6115: function(arg0, arg1) {
            arg0.onerror = arg1;
        },
        __wbg_set_onmessage_1403d0af3f624e31: function(arg0, arg1) {
            arg0.onmessage = arg1;
        },
        __wbg_set_type_0cf6993d8b04e2b0: function(arg0, arg1, arg2) {
            arg0.type = getStringFromWasm0(arg1, arg2);
        },
        __wbg_stack_0ed75d68575b0f3c: function(arg0, arg1) {
            const ret = arg1.stack;
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg_static_accessor_GLOBAL_THIS_4ee543f3784bd0fc: function() {
            const ret = typeof globalThis === 'undefined' ? null : globalThis;
            return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
        },
        __wbg_static_accessor_GLOBAL_e52e7d25649b4c36: function() {
            const ret = typeof global === 'undefined' ? null : global;
            return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
        },
        __wbg_static_accessor_SELF_5c5cb616569f5438: function() {
            const ret = typeof self === 'undefined' ? null : self;
            return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
        },
        __wbg_static_accessor_WINDOW_de8ecd752ccc840d: function() {
            const ret = typeof window === 'undefined' ? null : window;
            return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
        },
        __wbg_unshift_0eb6f1fa525bbb20: function(arg0, arg1) {
            const ret = arg0.unshift(arg1);
            return ret;
        },
        __wbindgen_cast_0000000000000001: function(arg0, arg1) {
            // Cast intrinsic for `Closure(Closure { dtor_idx: 879, function: Function { arguments: [NamedExternref("Event")], shim_idx: 880, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
            const ret = makeMutClosure(arg0, arg1, wasm.wasm_bindgen__closure__destroy__h654a391dc99e9a3f, wasm_bindgen__convert__closures_____invoke__hae6ad61c418d1e66);
            return ret;
        },
        __wbindgen_cast_0000000000000002: function(arg0, arg1) {
            // Cast intrinsic for `Closure(Closure { dtor_idx: 879, function: Function { arguments: [NamedExternref("MessageEvent")], shim_idx: 880, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
            const ret = makeMutClosure(arg0, arg1, wasm.wasm_bindgen__closure__destroy__h654a391dc99e9a3f, wasm_bindgen__convert__closures_____invoke__hae6ad61c418d1e66);
            return ret;
        },
        __wbindgen_cast_0000000000000003: function(arg0) {
            // Cast intrinsic for `F64 -> Externref`.
            const ret = arg0;
            return ret;
        },
        __wbindgen_cast_0000000000000004: function(arg0, arg1) {
            // Cast intrinsic for `Ref(String) -> Externref`.
            const ret = getStringFromWasm0(arg0, arg1);
            return ret;
        },
        __wbindgen_init_externref_table: function() {
            const table = wasm.__wbindgen_externrefs;
            const offset = table.grow(4);
            table.set(0, undefined);
            table.set(offset + 0, undefined);
            table.set(offset + 1, null);
            table.set(offset + 2, true);
            table.set(offset + 3, false);
        },
    };
    return {
        __proto__: null,
        "./dart_automerge_bg.js": import0,
    };
}

function wasm_bindgen__convert__closures_____invoke__hae6ad61c418d1e66(arg0, arg1, arg2) {
    wasm.wasm_bindgen__convert__closures_____invoke__hae6ad61c418d1e66(arg0, arg1, arg2);
}

const WorkerPoolFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_workerpool_free(ptr >>> 0, 1));

function addToExternrefTable0(obj) {
    const idx = wasm.__externref_table_alloc();
    wasm.__wbindgen_externrefs.set(idx, obj);
    return idx;
}

const CLOSURE_DTORS = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(state => state.dtor(state.a, state.b));

function debugString(val) {
    // primitive types
    const type = typeof val;
    if (type == 'number' || type == 'boolean' || val == null) {
        return  `${val}`;
    }
    if (type == 'string') {
        return `"${val}"`;
    }
    if (type == 'symbol') {
        const description = val.description;
        if (description == null) {
            return 'Symbol';
        } else {
            return `Symbol(${description})`;
        }
    }
    if (type == 'function') {
        const name = val.name;
        if (typeof name == 'string' && name.length > 0) {
            return `Function(${name})`;
        } else {
            return 'Function';
        }
    }
    // objects
    if (Array.isArray(val)) {
        const length = val.length;
        let debug = '[';
        if (length > 0) {
            debug += debugString(val[0]);
        }
        for(let i = 1; i < length; i++) {
            debug += ', ' + debugString(val[i]);
        }
        debug += ']';
        return debug;
    }
    // Test for built-in
    const builtInMatches = /\[object ([^\]]+)\]/.exec(toString.call(val));
    let className;
    if (builtInMatches && builtInMatches.length > 1) {
        className = builtInMatches[1];
    } else {
        // Failed to match the standard '[object ClassName]'
        return toString.call(val);
    }
    if (className == 'Object') {
        // we're a user defined class or Object
        // JSON.stringify avoids problems with cycles, and is generally much
        // easier than looping through ownProperties of `val`.
        try {
            return 'Object(' + JSON.stringify(val) + ')';
        } catch (_) {
            return 'Object';
        }
    }
    // errors
    if (val instanceof Error) {
        return `${val.name}: ${val.message}\n${val.stack}`;
    }
    // TODO we could test for more things here, like `Set`s and `Map`s.
    return className;
}

function getArrayU8FromWasm0(ptr, len) {
    ptr = ptr >>> 0;
    return getUint8ArrayMemory0().subarray(ptr / 1, ptr / 1 + len);
}

let cachedDataViewMemory0 = null;
function getDataViewMemory0() {
    if (cachedDataViewMemory0 === null || cachedDataViewMemory0.buffer.detached === true || (cachedDataViewMemory0.buffer.detached === undefined && cachedDataViewMemory0.buffer !== wasm.memory.buffer)) {
        cachedDataViewMemory0 = new DataView(wasm.memory.buffer);
    }
    return cachedDataViewMemory0;
}

function getStringFromWasm0(ptr, len) {
    ptr = ptr >>> 0;
    return decodeText(ptr, len);
}

let cachedUint8ArrayMemory0 = null;
function getUint8ArrayMemory0() {
    if (cachedUint8ArrayMemory0 === null || cachedUint8ArrayMemory0.byteLength === 0) {
        cachedUint8ArrayMemory0 = new Uint8Array(wasm.memory.buffer);
    }
    return cachedUint8ArrayMemory0;
}

function handleError(f, args) {
    try {
        return f.apply(this, args);
    } catch (e) {
        const idx = addToExternrefTable0(e);
        wasm.__wbindgen_exn_store(idx);
    }
}

function isLikeNone(x) {
    return x === undefined || x === null;
}

function makeMutClosure(arg0, arg1, dtor, f) {
    const state = { a: arg0, b: arg1, cnt: 1, dtor };
    const real = (...args) => {

        // First up with a closure we increment the internal reference
        // count. This ensures that the Rust closure environment won't
        // be deallocated while we're invoking it.
        state.cnt++;
        const a = state.a;
        state.a = 0;
        try {
            return f(a, state.b, ...args);
        } finally {
            state.a = a;
            real._wbg_cb_unref();
        }
    };
    real._wbg_cb_unref = () => {
        if (--state.cnt === 0) {
            state.dtor(state.a, state.b);
            state.a = 0;
            CLOSURE_DTORS.unregister(state);
        }
    };
    CLOSURE_DTORS.register(real, state, state);
    return real;
}

function passArrayJsValueToWasm0(array, malloc) {
    const ptr = malloc(array.length * 4, 4) >>> 0;
    for (let i = 0; i < array.length; i++) {
        const add = addToExternrefTable0(array[i]);
        getDataViewMemory0().setUint32(ptr + 4 * i, add, true);
    }
    WASM_VECTOR_LEN = array.length;
    return ptr;
}

function passStringToWasm0(arg, malloc, realloc) {
    if (realloc === undefined) {
        const buf = cachedTextEncoder.encode(arg);
        const ptr = malloc(buf.length, 1) >>> 0;
        getUint8ArrayMemory0().subarray(ptr, ptr + buf.length).set(buf);
        WASM_VECTOR_LEN = buf.length;
        return ptr;
    }

    let len = arg.length;
    let ptr = malloc(len, 1) >>> 0;

    const mem = getUint8ArrayMemory0();

    let offset = 0;

    for (; offset < len; offset++) {
        const code = arg.charCodeAt(offset);
        if (code > 0x7F) break;
        mem[ptr + offset] = code;
    }
    if (offset !== len) {
        if (offset !== 0) {
            arg = arg.slice(offset);
        }
        ptr = realloc(ptr, len, len = offset + arg.length * 3, 1) >>> 0;
        const view = getUint8ArrayMemory0().subarray(ptr + offset, ptr + len);
        const ret = cachedTextEncoder.encodeInto(arg, view);

        offset += ret.written;
        ptr = realloc(ptr, len, offset, 1) >>> 0;
    }

    WASM_VECTOR_LEN = offset;
    return ptr;
}

function takeFromExternrefTable0(idx) {
    const value = wasm.__wbindgen_externrefs.get(idx);
    wasm.__externref_table_dealloc(idx);
    return value;
}

let cachedTextDecoder = new TextDecoder('utf-8', { ignoreBOM: true, fatal: true });
cachedTextDecoder.decode();
const MAX_SAFARI_DECODE_BYTES = 2146435072;
let numBytesDecoded = 0;
function decodeText(ptr, len) {
    numBytesDecoded += len;
    if (numBytesDecoded >= MAX_SAFARI_DECODE_BYTES) {
        cachedTextDecoder = new TextDecoder('utf-8', { ignoreBOM: true, fatal: true });
        cachedTextDecoder.decode();
        numBytesDecoded = len;
    }
    return cachedTextDecoder.decode(getUint8ArrayMemory0().subarray(ptr, ptr + len));
}

const cachedTextEncoder = new TextEncoder();

if (!('encodeInto' in cachedTextEncoder)) {
    cachedTextEncoder.encodeInto = function (arg, view) {
        const buf = cachedTextEncoder.encode(arg);
        view.set(buf);
        return {
            read: arg.length,
            written: buf.length
        };
    };
}

let WASM_VECTOR_LEN = 0;

let wasmModule, wasm;
function __wbg_finalize_init(instance, module) {
    wasm = instance.exports;
    wasmModule = module;
    cachedDataViewMemory0 = null;
    cachedUint8ArrayMemory0 = null;
    wasm.__wbindgen_start();
    return wasm;
}

async function __wbg_load(module, imports) {
    if (typeof Response === 'function' && module instanceof Response) {
        if (typeof WebAssembly.instantiateStreaming === 'function') {
            try {
                return await WebAssembly.instantiateStreaming(module, imports);
            } catch (e) {
                const validResponse = module.ok && expectedResponseType(module.type);

                if (validResponse && module.headers.get('Content-Type') !== 'application/wasm') {
                    console.warn("`WebAssembly.instantiateStreaming` failed because your server does not serve Wasm with `application/wasm` MIME type. Falling back to `WebAssembly.instantiate` which is slower. Original error:\n", e);

                } else { throw e; }
            }
        }

        const bytes = await module.arrayBuffer();
        return await WebAssembly.instantiate(bytes, imports);
    } else {
        const instance = await WebAssembly.instantiate(module, imports);

        if (instance instanceof WebAssembly.Instance) {
            return { instance, module };
        } else {
            return instance;
        }
    }

    function expectedResponseType(type) {
        switch (type) {
            case 'basic': case 'cors': case 'default': return true;
        }
        return false;
    }
}

function initSync(module) {
    if (wasm !== undefined) return wasm;


    if (module !== undefined) {
        if (Object.getPrototypeOf(module) === Object.prototype) {
            ({module} = module)
        } else {
            console.warn('using deprecated parameters for `initSync()`; pass a single object instead')
        }
    }

    const imports = __wbg_get_imports();
    if (!(module instanceof WebAssembly.Module)) {
        module = new WebAssembly.Module(module);
    }
    const instance = new WebAssembly.Instance(module, imports);
    return __wbg_finalize_init(instance, module);
}

async function __wbg_init(module_or_path) {
    if (wasm !== undefined) return wasm;


    if (module_or_path !== undefined) {
        if (Object.getPrototypeOf(module_or_path) === Object.prototype) {
            ({module_or_path} = module_or_path)
        } else {
            console.warn('using deprecated parameters for the initialization function; pass a single object instead')
        }
    }

    if (module_or_path === undefined) {
        module_or_path = new URL('dart_automerge_bg.wasm', import.meta.url);
    }
    const imports = __wbg_get_imports();

    if (typeof module_or_path === 'string' || (typeof Request === 'function' && module_or_path instanceof Request) || (typeof URL === 'function' && module_or_path instanceof URL)) {
        module_or_path = fetch(module_or_path);
    }

    const { instance, module } = await __wbg_load(await module_or_path, imports);

    return __wbg_finalize_init(instance, module);
}

export { initSync, __wbg_init as default };
