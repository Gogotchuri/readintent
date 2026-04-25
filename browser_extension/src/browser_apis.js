const TOKEN_KEY = "SESSION_TOKEN";
const DEVICE_ID_KEY = "DEVICE_ID";
const USER_CODE = "USER_CODE";

// Unify browser APIs. Chrome only support chrome and the Firefox supports both browser and chrome.
// The API is the same if we are using Chrom (>= 95) and Firefox (>=115)
export const api = typeof browser !== "undefined" ? browser : chrome;
export const sessionStorage = {
  /**
   * Helper method to set a value in storage
   * @param {string} key storage key
   * @param {string} value value to be saved
   * @returns {Promise<Error|null>} returns error if any occured, or null
   */
  async _setValue(key, value) {
    try {
      await api.storage.local.set({ [key]: value });
      return null;
    } catch (e) {
      return e;
    }
  },

  /**
   * Helper method to get a value from storage
   * @param {string} key storage key
   * @param {string} errorMessage error message if value not found
   * @returns {Promise<[string|null, Error|null]>} returns a tuple with value and error
   */
  async _getValue(key, errorMessage) {
    try {
      const result = await api.storage.local.get(key);
      const value = result[key];
      if (!value) {
        return [null, new Error(errorMessage)];
      }
      return [value, null];
    } catch (e) {
      return [null, e];
    }
  },

  /**
   * Saves session token in a storage, provided by the browser API
   * @param {string} token session token to be saved
   * @returns {Promise<Error|null>} returns error if any occured, or null
   */
  async setSessionToken(token) {
    return this._setValue(TOKEN_KEY, token);
  },

  /**
   * Retrieves session token from storage and returns non-null error in case of failure
   * @returns {Promise<[string|null, Error|null]>} returns a tuple with token and error
   */
  async getSessionToken() {
    return this._getValue(TOKEN_KEY, "Session token not set");
  },

  /**
   * Saves device ID in a storage, provided by the browser API
   * @param {string} deviceId device ID to be saved
   * @returns {Promise<Error|null>} returns error if any occured, or null
   */
  async setDeviceId(deviceId) {
    return this._setValue(DEVICE_ID_KEY, deviceId);
  },

  /**
   * Retrieves device ID from storage and returns error in case of failure
   * @returns {Promise<[string|null, Error|null]>} returns a tuple with device ID and error.
   */
  async getDeviceId() {
    return this._getValue(DEVICE_ID_KEY, "Device ID not set");
  },

  /**
   * Saves user code in a storage, provided by the browser API
   * @param {string} userCode user code to be saved
   * @returns {Promise<Error|null>} returns error if any occured, or null
   */
  async setUserCode(userCode) {
    return this._setValue(USER_CODE, userCode);
  },

  /**
   * Retrieves user code from storage and returns error in case of failure
   * @returns {Promise<[string|null, Error|null]>} returns a tuple with user code and error.
   */
  async getUserCode() {
    return this._getValue(USER_CODE, "User code not set");
  },

  /**
   * Listen to SESSION_TOKEN updates
   * @param {Function} f
   */
  addSessionTokenListener(f) {
    api.storage.onChanged.addListener(this._getChangeListener(TOKEN_KEY, f));
  },

  /**
   * Listen to USER_CODE updates
   * @param {Function} f
   */
  addUserCodeListener(f) {
    api.storage.onChanged.addListener(this._getChangeListener(USER_CODE, f));
  },

  /**
   * This is a generator function watching storage local change for specific key
   * @param {string} key to watch changes for
   * @returns listener function
   */
  _getChangeListener(key, callback) {
    return (changes, area) => {
      if (area != "local") return;
      if (!(key in changes)) return;
      callback(changes[key]);
    };
  },
};

export const tabs = api.tabs;
export const scripting = api.scripting;
export const runtime = api.runtime;
