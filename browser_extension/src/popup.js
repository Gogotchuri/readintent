import { sessionStorage } from "./browser_apis.js";

const elByID = (id) => document.getElementById(id);

// Element references
const unpairedStateEl = elByID("state-unpaired");
const pairingStateEl = elByID("state-pairing");
const pairedStateEl = elByID("state-paired");

const codeEl = elByID("code-display");
const unpairBtn = elByID("unpair-btn");

function showState(state) {
  switch (state) {
    case "unpaired":
      unpairedStateEl.hidden = false;
      pairingStateEl.hidden = true;
      pairedStateEl.hidden = true;
      break;
    case "pairing":
      unpairedStateEl.hidden = true;
      pairingStateEl.hidden = false;
      pairedStateEl.hidden = true;
      break;
    case "paired":
      unpairedStateEl.hidden = true;
      pairingStateEl.hidden = true;
      pairedStateEl.hidden = false;
      unpairBtn.hidden = false;
      break;
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
    //Nothing to do here, we have paired state and rendered everything already
    return;
  }
  if (state === "unpaired") {
    //TODO start pairing
    return;
  }
  if (state === "pairing") {
    //TODO resume polling we have the code up waiting for the user action
  }
}

//TODO event listeners

// Init
(async () => {
  addStorageListeners();
  const state = await render();
  initializeFromState(state);
})();
