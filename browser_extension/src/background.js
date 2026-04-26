// Most medium to long running processes should ideally be done in the background for the extension
// otherwise user might accidentally cancer the requests mid-flight and cause issues

import { checkPairingStatus, requestCodes } from "./api.js";
import { scripting, sessionStorage, tabs } from "./browser_apis.js";

let pollTimer = null;

async function startPairing() {
  let [res, err] = await requestCodes();
  if (err) {
    return err;
  }
  err = await sessionStorage.setPairingMode(
    res.device_code,
    res.user_code,
    res.expires_in,
    res.interval,
  );
  if (err) {
    return err;
  }
  startPolling(res.interval);
}

async function checkStatus() {
  const pairingObject = await sessionStorage.getPairingModeObject();
  // If pairingObject is null, we either haven't got codes yet, or they have expired and we should stop pooling
  if (!pairingObject) {
    await sessionStorage.resetAll();
    stopPolling();
    return;
  }
  const [res, err] = await checkPairingStatus(pairingObject.deviceCode);
  // Likely an temporary issue, we should continue polling
  if (err) {
    return;
  }

  // If we paired successfully we need to set the state correctly and stop polling
  if (res.status === "paired") {
    sessionStorage.setSessionToken(res.session_token);
    stopPolling();
    return;
  }

  //If we have expired status we clear and stop polling as the first case
  if (res.status === "expired") {
    await sessionStorage.resetAll();
    stopPolling();
    return;
  }

  // If we haven't returned so far we should continue polling
}

function startPolling(intervalSec) {
  stopPolling();
  pollTimer = setInterval(checkStatus, intervalSec * 1000);
}

function stopPolling() {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
}

async function unpair() {
  await sessionStorage.resetAll();
  stopPolling();
}

async function extractContentFromActiveTab() {
  const [tab] = await tabs.query({ active: true, currentWindow: true });
  if (!tab?.id) return [null, new Error("Active tab not found")];

  const results = await scripting.executeScript({
    target: { tabId: tab.id },
    files: ["src/content_extraction.js"],
  });

  const payload = results?.[0]?.results;
  if (!payload?.url) return [null, new Error("Couldn't read active page")];

  return [payload, null];
}

runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  (async () => {
    try {
      switch (msg.type) {
        case "START_PAIRING":
          //TODO
          break;
        case "UNPAIR":
          //TODO
          break;
        case "SEND_URL":
          //TODO
          break;
        case "RESUME_POLLING": {
          //TODO
          break;
        }
        default:
          sendResponse({ ok: false, error: "unknown message" });
      }
    } catch (e) {
      sendResponse({ ok: false, error: String(e.message || e) });
    }
  })();
  return true; // keep channel open for async sendResponse
});
(async () => {
  const state = await sessionStorage.determineAuthState();
  if (state === "pairing") {
    startPolling();
  }
})();
