// content.js - The script that interacts with the TherapyBoss web page

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === "FILL_NOTE") {
    const noteText = request.text;
    
    // 1. Try to find the main note textarea
    // We search for common TherapyBoss patterns: textareas with 'note' or 'soap' in id/class/name
    const textarea = findNoteTextarea();
    
    if (!textarea) {
      sendResponse({ success: false, error: "Could not find the note text box on this page. Please ensure you are on the correct TherapyBoss screen." });
      return;
    }

    // 2. Check for existing content and ask for confirmation
    if (textarea.value.trim() !== "") {
      const confirmed = confirm("The note box already contains text. Do you want to overwrite it?");
      if (!confirmed) {
        sendResponse({ success: false, error: "Overwrite cancelled by user." });
        return;
      }
    }

    // 3. Inject the text
    textarea.value = noteText;
    
    // Trigger 'input' and 'change' events so the website's JavaScript knows the text changed
    textarea.dispatchEvent(new Event('input', { bubbles: true }));
    textarea.dispatchEvent(new Event('change', { bubbles: true }));

    sendResponse({ success: true });
  }
});

function findNoteTextarea() {
  // Strategy A: Look for common ID/Name patterns in TherapyBoss
  const selectors = [
    'textarea[id*="note"]',
    'textarea[name*="note"]',
    'textarea[class*="note"]',
    'textarea[id*="soap"]',
    'textarea[id*="treatment"]',
    'textarea[name*="treatment"]',
    'textarea[id*="daily"]',
    '.note-editor',
    '#note-content'
  ];

  for (let selector of selectors) {
    const el = document.querySelector(selector);
    if (el && el.tagName === 'TEXTAREA') return el;
  }

  // Strategy B: Find the largest textarea on the page (usually the note box)
  const allTextareas = Array.from(document.querySelectorAll('textarea'));
  if (allTextareas.length > 0) {
    return allTextareas.reduce((prev, current) => {
      return (prev.clientHeight * prev.clientWidth > current.clientHeight * current.clientWidth) ? prev : current;
    });
  }

  return null;
}
