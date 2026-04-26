import { runtime, sessionStorage } from "./browser_apis.js";

const elByID = (id) => document.getElementById(id);

// Element references
const unpairedStateEl = elByID("state-unpaired");
const pairingStateEl = elByID("state-pairing");
const pairedStateEl = elByID("state-paired");
const states = {
  paired: pairedStateEl,
  unpaired: unpairedStateEl,
  pairing: pairingStateEl,
};

const codeEl = elByID("code-display");
const unpairBtn = elByID("unpair-btn");
const sendPageBtn = elByID("send-page-btn");
const sendCustomBtn = elByID("send-custom-btn");
const customUrlInput = elByID("custom-url");
const statusMsg = elByID("status-message");
const statusDotPaired = elByID("status-paired");
const statusDotPairing = elByID("status-pairing");
const statusDotUnpaired = elByID("status-unpaired");
const statusDots = {
  paired: statusDotPaired,
  unpaired: statusDotUnpaired,
  pairing: statusDotPairing,
};

function showFeedback(text, isError = false) {
  statusMsg.textContent = text;
  statusMsg.classList.toggle("error", isError);
  statusMsg.classList.toggle("success", !isError);
  statusMsg.hidden = false;
  setTimeout(() => {
    statusMsg.hidden = true;
  }, 3000);
}

function showState(state) {
  // Hide everything
  for (const s of ["paired", "pairing", "unpaired"]) {
    statusDots[s].hidden = true;
    states[s].hidden = true;
  }
  // Show the current status status and states
  statusDots[state].hidden = false;
  states[state].hidden = false;

  // Show or hide unpair button
  if (state === "paired") {
    unpairBtn.hidden = false;
  } else {
    unpairBtn.hidden = true;
  }
}

async function userCodeUpdated() {
  // If we have session token already we shouldn't show pairing mode
  // This check avoids weird race conditions
  const [sessionToken, tokenErr] = await sessionStorage.getSessionToken();
  if (!tokenErr && sessionToken) return;

  const [code, err] = await sessionStorage.getUserCode();
  if (err || !code) return;
  codeEl.textContent = code;
  showState("pairing");
}

async function sessionTokenUpdated() {
  const [sessionToken, err] = await sessionStorage.getSessionToken();
  if (err || !sessionToken) return;
  showState("paired");
}

// We are using background worker to set the session token and need to watch for changes
function addStorageListeners() {
  sessionStorage.addUserCodeListener(userCodeUpdated);
  sessionStorage.addSessionTokenListener(sessionTokenUpdated);
}

// General rendering function detects and shows the state. Returns the state
async function render() {
  const state = await sessionStorage.determineAuthState();
  if (state !== "pairing") {
    showState(state);
    return state;
  }
  // For the case of pairing
  const [code, codeErr] = await sessionStorage.getUserCode();
  if (!codeErr && code) {
    codeEl.textContent = code;
    showState(state);
    return state;
  }
  // If we haven't returned yet, there likely has been an issue with code and let's change the state to unpaired
  return "unpaired";
}

function initializeFromState(state) {
  if (state === "paired") {
    return;
  }
  if (state === "unpaired") {
    runtime.sendMessage({ type: "START_PAIRING" }).then((res) => {
      if (!res?.ok) showFeedback(res?.error || "Failed to start pairing", true);
      //Try in 5 seconds
      setTimeout(() => initializeFromState(state), 5000);
    });
    return;
  }
  if (state === "pairing") {
    runtime.sendMessage({ type: "RESUME_POLLING" }).then((res) => {
      if (!res?.ok)
        showFeedback(res?.error || "Failed to resume polling", true);
    });
  }
}

// Event listeners

unpairBtn.addEventListener("click", async () => {
  await runtime.sendMessage({ type: "UNPAIR" });
  const state = await render();
  initializeFromState(state);
});

sendPageBtn.addEventListener("click", async () => {
  sendPageBtn.disabled = true;
  showFeedback("Sending...");
  const res = await runtime.sendMessage({
    type: "SEND_URL",
    extractFromTab: true,
  });
  sendPageBtn.disabled = false;
  if (res?.ok) {
    showFeedback("Sent!");
  } else {
    showFeedback(res?.error || "Failed to send page", true);
  }
});

sendCustomBtn.addEventListener("click", async () => {
  const url = customUrlInput.value.trim();
  if (!url) {
    showFeedback("Please enter a URL", true);
    return;
  }
  sendCustomBtn.disabled = true;
  showFeedback("Sending...");
  const res = await runtime.sendMessage({ type: "SEND_URL", url });
  sendCustomBtn.disabled = false;
  if (res?.ok) {
    showFeedback("Sent!");
    customUrlInput.value = "";
  } else {
    showFeedback(res?.error || "Failed to send URL", true);
  }
});

// Init
(async () => {
  addStorageListeners();
  const state = await render();
  initializeFromState(state);
})();
