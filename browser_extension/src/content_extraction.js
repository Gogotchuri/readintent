// Executes the script on the tab to extract the URL and the cleaned DOM
// Used to post the already rendered content to reduce the scraping overhead and
// work through paywall by reusing DOM rendered in already authenticated session
(function cleanAndExtractDOM() {
  const doc = document.cloneNode(true);

  const dropElements = (sel) =>
    doc.querySelectorAll(sel).forEach((n) => n.remove());

  const thingsToDrop = ["script", "noscript", "iframe"];
  thingsToDrop.forEach(dropElements);

  // Remove inline enevt handlers and embedded "javascript" in strings
  // Just to be safe, we arent going to actually execute those scripts on server
  // Trafilatura will simply take the HTML and convert it
  doc.querySelectorAll("*").forEach((el) => {
    for (const attr of Array.from(el.attributes)) {
      const n = attr.name.toLowerCase();
      if (n.startsWith("on")) el.removeAttribute(attr.name);
      if ((n === "href" || n === "src") && /^javascript:/i.test(attr.value)) {
        el.removeAttribute(attr.name);
      }
    }
  });
  return {
    url: location.href,
    html: "<!DOCTYPE html>\n" + doc.documentElement.outerHTML,
  };
})();
