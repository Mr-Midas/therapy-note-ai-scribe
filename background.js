chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === "GENERATE_NOTE") {
    const OLLAMA_ENDPOINT = "http://localhost:11434/api/generate";
    const MODEL = "phi3";

    fetch(OLLAMA_ENDPOINT, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: MODEL,
        stream: false,
        system: request.systemPrompt,
        prompt: request.prompt,
        options: {
          temperature: 0.3,
          top_p: 0.9,
          num_predict: 1024
        }
      })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`Ollama responded with status ${response.status}`);
      }
      return response.json();
    })
    .then(data => sendResponse({ success: true, response: data.response }))
    .catch(error => sendResponse({ success: false, error: error.message }));

    return true; 
  }

  if (request.type === "FILL_NOTE") {
    // Send the note text to the active tab's content script
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      if (tabs[0]) {
        chrome.tabs.sendMessage(tabs[0].id, { type: "FILL_NOTE", text: request.text }, (response) => {
          if (chrome.runtime.lastError) {
            sendResponse({ success: false, error: "Could not connect to page. Please refresh TherapyBoss." });
          } else {
            sendResponse(response);
          }
        });
      } else {
        sendResponse({ success: false, error: "No active tab found." });
      }
    });
    return true;
  }
});

