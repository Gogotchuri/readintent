# ReadIntent Browser Extension

This extension uses manifest V3 extension to allow cross-browser compatibility.
We authenticate with pair code and mobile app.
This extension has a simple job of sending URLs of articles to backend for parsing and delivery to user.
If the user want to select the current page we will also send the rendered HTML alongside to make the process of parsing the article faster and more reliable.
Sending the rendered (and cleaned) HTML also has additional benefits of accessing paywalled sources that user can see on their authenticated browser session but the scraper won't be able to extract.

## Authentication
This extension implements "OAuth 2.0 Device Authorization Grant" ([RFC8628](https://datatracker.ietf.org/doc/html/rfc8628))
with slight modification of not supporting auth by URLs and only supports verification with user code.
