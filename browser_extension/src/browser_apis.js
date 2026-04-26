const TOKEN_KEY = "SESSION_TOKEN";
const DEVICE_CODE_KEY = "DEVICE_ID";
const USER_CODE_KEY = "USER_CODE";
const POOLING_INTERVAL_KEY = "POOLING_INTERVAL_KEY";
const EXPIRES_AT_KEY = "EXPIRES_AT_KEY";

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
   * Sets pairing mode variables
   * @param {string} deviceCode
   * @param {string} userCode
   * @param {number} expiresInSec
   * @param {number} intervalSec
   * @returns {Promise<Error|null>}
   */
  async setPairingMode(deviceCode, userCode, expiresInSec, intervalSec) {
    const expiresAt = Date.now() + expiresInSec * 1000;
    const pairingObject = {
      [DEVICE_CODE_KEY]: deviceCode,
      [USER_CODE_KEY]: userCode,
      [POOLING_INTERVAL_KEY]: intervalSec,
      [EXPIRES_AT_KEY]: expiresAt,
    };

    try {
      await api.storage.local.set(pairingObject);
      return null;
    } catch (e) {
      return e;
    }
  },

  /**
   * Retrieves pairing mode object from storage
   * @returns {Promise<{deviceCode: string|null, userCode: string|null, intervalSec: number|null, expiresAt: number|null}|null>} returns pairing mode object or null on error
   */
  async getPairingModeObject() {
    try {
      const result = await api.storage.local.get([
        DEVICE_CODE_KEY,
        USER_CODE_KEY,
        POOLING_INTERVAL_KEY,
        EXPIRES_AT_KEY,
      ]);
      // If the user or device codes are null or we are past the expire date, we need to return null
      if (
        !result[DEVICE_CODE_KEY] ||
        !result[USER_CODE_KEY] ||
        Date.now() > result[EXPIRES_AT_KEY]
      ) {
        return null;
      }
      return {
        deviceCode: result[DEVICE_CODE_KEY] || null,
        userCode: result[USER_CODE_KEY] || null,
        intervalSec: result[POOLING_INTERVAL_KEY] || null,
        expiresAt: result[EXPIRES_AT_KEY] || null,
      };
    } catch (e) {
      console.error(e);
      return null;
    }
  },

  /**
   * Retrieves user code from storage with expiration check
   * @returns {Promise<[string|null, Error|null]>} returns a tuple with user code and error
   */
  async getUserCode() {
    try {
      const result = await api.storage.local.get([
        USER_CODE_KEY,
        EXPIRES_AT_KEY,
      ]);
      const userCode = result[USER_CODE_KEY];
      const expiresAt = result[EXPIRES_AT_KEY];

      if (!userCode) {
        return [null, new Error("User code not set")];
      }

      if (expiresAt && Date.now() > expiresAt) {
        return [null, new Error("User code has expired")];
      }

      return [userCode, null];
    } catch (e) {
      return [null, e];
    }
  },

  async resetAll() {
    return await api.storage.local.remove([
      USER_CODE_KEY,
      DEVICE_CODE_KEY,
      EXPIRES_AT_KEY,
      POOLING_INTERVAL_KEY,
      TOKEN_KEY,
    ]);
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
    api.storage.onChanged.addListener(
      this._getChangeListener(USER_CODE_KEY, f),
    );
  },

  /**
   * Returns the state of the auth, based on the stored values
   * @returns {Promise<"unpaired"|"pairing"|"paired">}
   */
  async determineAuthState() {
    try {
      const values = await api.storage.local.get([
        TOKEN_KEY,
        USER_CODE_KEY,
        EXPIRES_AT_KEY,
      ]);
      if (values[TOKEN_KEY]) {
        return "paired";
      }
      if (values[USER_CODE_KEY]) {
        // Check if user code has expired
        if (values[EXPIRES_AT_KEY] && Date.now() > values[EXPIRES_AT_KEY]) {
          return "unpaired";
        }
        return "pairing";
      }
      return "unpaired";
    } catch (e) {
      console.error(e);
      return "unpaired";
    }
  },

  /**
   * This is a generator function watching storage local change for specific key
   * @param {string} key to watch changes for
   * @returns listener function
   */
  _getChangeListener(key, callback) {
    return (changes, area) => {
      if (area !== "local") return;
      if (!(key in changes)) return;
      callback(changes[key]);
    };
  },
};

export const tabs = api.tabs;
export const scripting = api.scripting;
export const runtime = api.runtime;
