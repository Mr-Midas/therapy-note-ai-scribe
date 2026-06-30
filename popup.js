const SYSTEM_PROMPT = `You are an expert Home Health Therapist Scribe specializing in Medicare-compliant clinical documentation for the TherapyBoss EMR.

Your job is to transform raw shorthand notes into a professional, objective, and legally defensible Daily Treatment Note.

CRITICAL FORMATTING RULES:
1. NO MARKDOWN: Do not use asterisks (**), hashtags (#), or any bolding/italics. Use plain text only.
2. NO PLACEHOLDERS: Do not use brackets like [insert...], ellipses (...), or blanks. If a piece of information is not provided in the raw notes, simply omit that part of the note. Do not invent data.
3. DYNAMIC SOAP: Use headers (Subjective, Objective, Assessment, Plan) ONLY for sections where you have actual data. If there is no "Subjective" info, skip the Subjective header entirely.

CLINICAL COMPLIANCE RULES:
1. PROVE SKILLED NEED: Use active, skilled terminology (e.g., "Therapist facilitated...", "Gait training provided with...", "Tactile cues required for...", "Instructed patient in..."). Avoid passive language like "patient walked" or "tolerated well".
2. OBJECTIVE MEASUREMENT: Include exact sets, reps, distances, and levels of assistance (Standby Assist, Min A, Mod A, Max A) provided. Format them clinically.
3. CONNECT TO FUNCTION: Always tie the intervention back to a functional goal (e.g., "to improve balance for safe tub transfers").

EXAMPLE OUTPUT:
Subjective: Patient reports right shoulder pain at 5/10 and difficulty with upper body dressing.
Objective:
- Therapeutic Exercise: Facilitated active range of motion (AROM) of the right upper extremity for 10 minutes to improve joint mobility.
- ADL Training: Instructed patient in upper body dressing utilizing adaptive equipment (reacher). Patient required Mod A for task completion.
Assessment: Patient demonstrates impaired right upper extremity AROM and decreased independence with upper body dressing. Skilled intervention required to maximize safety.
Plan: Continue OT per plan of care. Will progress to Min A for upper body dressing.

INSTRUCTIONS:
Transform the following raw notes into a compliant TherapyBoss note following the rules above. Use plain text only.`;

const OLLAMA_ENDPOINT = "http://localhost:11434/api/generate";
const MODEL = "phi3"; // Switched to phi3 for significantly faster performance on 8GB Macs

const rawNotes = document.getElementById("rawNotes");
const outputNotes = document.getElementById("outputNotes");
const generateBtn = document.getElementById("generateBtn");
const fillBtn = document.getElementById("fillBtn");
const fillButtonRow = document.getElementById("fillButtonRow");
const copyBtn = document.getElementById("copyBtn");
const clearBtn = document.getElementById("clearBtn");
const outputSection = document.getElementById("outputSection");
const statusBar = document.getElementById("statusBar");
const themeToggle = document.getElementById("themeToggle");
const themeIcon = document.getElementById("themeIcon");

// ── State Persistence (Auto-Save/Restore) ───────────────────

async function saveState() {
  await chrome.storage.local.set({
    savedRawNotes: rawNotes.value,
    savedOutputNotes: outputNotes.value
  });
}

async function loadState() {
  const data = await chrome.storage.local.get(["savedRawNotes", "savedOutputNotes"]);
  if (data.savedRawNotes) {
    rawNotes.value = data.savedRawNotes;
  }
  if (data.savedOutputNotes) {
    outputNotes.value = data.savedOutputNotes;
    if (data.savedOutputNotes.trim() !== "") {
      outputSection.classList.add("visible");
    }
  }
}

// Auto-save raw notes on every keystroke
rawNotes.addEventListener("input", saveState);

// ── Theme Toggle ──────────────────────────────────────────────

function loadTheme() {
  const saved = localStorage.getItem("therapyNoteTheme");
  const theme = saved || "light";
  document.documentElement.setAttribute("data-theme", theme);
  themeIcon.textContent = theme === "dark" ? "☀️" : "🌙";
}

themeToggle.addEventListener("click", () => {
  const current = document.documentElement.getAttribute("data-theme");
  const next = current === "dark" ? "light" : "dark";
  document.documentElement.setAttribute("data-theme", next);
  localStorage.setItem("therapyNoteTheme", next);
  themeIcon.textContent = next === "dark" ? "☀️" : "🌙";
});

loadTheme();

// ── Status Bar ────────────────────────────────────────────────

function showStatus(message, type) {
  statusBar.textContent = message;
  statusBar.className = `status-bar visible ${type}`;
}

function hideStatus() {
  statusBar.className = "status-bar";
}

// ── Generate Note ─────────────────────────────────────────────

generateBtn.addEventListener("click", async () => {
  const notes = rawNotes.value.trim();

  if (!notes) {
    showStatus("Please enter your raw notes first.", "error");
    return;
  }

  hideStatus();
  outputSection.classList.remove("visible");
  generateBtn.classList.add("loading");
  generateBtn.disabled = true;
  copyBtn.textContent = "📋 Copy";
  copyBtn.classList.remove("copied");

  try {
    const response = await fetch(OLLAMA_ENDPOINT, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: MODEL,
        stream: false,
        system: SYSTEM_PROMPT,
        prompt: notes,
        options: {
          temperature: 0.3,
          top_p: 0.9,
          num_predict: 1024 // Reduced for faster generation on 8GB RAM
        }
      })
    });

    if (!response.ok) {
      throw new Error(`Ollama responded with status ${response.status}`);
    }

    const data = await response.json();

    if (!data.response || data.response.trim() === "") {
      throw new Error("Ollama returned an empty response.");
    }

    outputNotes.value = data.response.trim();
    outputSection.classList.add("visible");
    fillButtonRow.style.display = "flex";
    showStatus("Note generated successfully. Review before copying to TherapyBoss.", "success");
    
    // Save result to storage
    saveState();
  } catch (err) {
    let msg = err.message;
    if (err.name === "TypeError" && msg.includes("fetch")) {
      msg = "Cannot connect to Ollama. Make sure Ollama is running (open Terminal, type: ollama serve).";
    }
    showStatus(`Error: ${msg}`, "error");
  } finally {
    generateBtn.classList.remove("loading");
    generateBtn.disabled = false;
  }
});

// ── Fill in TherapyBoss ────────────────────────────────────

fillBtn.addEventListener("click", async () => {
  const text = outputNotes.value.trim();
  if (!text) {
    showStatus("Nothing to fill. Generate a note first.", "error");
    return;
  }

  try {
    const response = await new Promise((resolve, reject) => {
      chrome.runtime.sendMessage(
        { type: "FILL_NOTE", text: text },
        (res) => {
          if (chrome.runtime.lastError) {
            reject(new Error(chrome.runtime.lastError.message));
          } else {
            resolve(res);
          }
        }
      );
    });

    if (response.success) {
      showStatus("Successfully filled in TherapyBoss!", "success");
    } else {
      showStatus(`Error: ${response.error}`, "error");
    }
  } catch (err) {
    showStatus(`Error: ${err.message}`, "error");
  }
});

// ── Copy to Clipboard ────────────────────────────────────────

copyBtn.addEventListener("click", async () => {
  const text = outputNotes.value;
  if (!text) return;

  try {
    await navigator.clipboard.writeText(text);
    copyBtn.textContent = "✓ Copied!";
    copyBtn.classList.add("copied");
    setTimeout(() => {
      copyBtn.textContent = "📋 Copy";
      copyBtn.classList.remove("copied");
    }, 2000);
  } catch {
    outputNotes.select();
    document.execCommand("copy");
    copyBtn.textContent = "✓ Copied!";
    copyBtn.classList.add("copied");
    setTimeout(() => {
      copyBtn.textContent = "📋 Copy";
      copyBtn.classList.remove("copied");
    }, 2000);
  }
});

// ── Clear ─────────────────────────────────────────────────────

clearBtn.addEventListener("click", async () => {
  rawNotes.value = "";
  outputNotes.value = "";
  outputSection.classList.remove("visible");
  fillButtonRow.style.display = "none";
  hideStatus();
  rawNotes.focus();
  await saveState();
});

// ── Keyboard Shortcut ────────────────────────────────────────

rawNotes.addEventListener("keydown", (e) => {
  if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
    e.preventDefault();
    generateBtn.click();
  }
});

// Init persistence
loadState();
