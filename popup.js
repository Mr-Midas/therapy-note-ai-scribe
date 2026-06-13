const SYSTEM_PROMPT = `You are an expert Home Health Therapist Scribe specializing in Medicare-compliant clinical documentation for the TherapyBoss EMR.

Your job is to transform the therapist's raw, messy shorthand or dictated notes into a highly professional, objective, and legally defensible Daily Treatment Note.

CRITICAL COMPLIANCE RULES (MEDICARE & THERAPYBOSS STANDARDS):
1. PROVE SKILLED NEED: Never use passive or unskilled language (e.g., "patient walked", "patient did exercises", "tolerated well"). You must use active, skilled terminology that proves the intervention required a licensed clinician (e.g., "Therapist facilitated...", "Gait training provided with...", "Tactile cues required for...", "Instructed patient in...").
2. OBJECTIVE MEASUREMENT: Include exact sets, reps, distances, and levels of assistance (Standby Assist, Min A, Mod A, Max A) provided in the raw notes. Do not hallucinate numbers if they are not provided, but format them clinically.
3. CONNECT TO FUNCTION: Always tie the exercise or intervention back to a functional goal (e.g., "to improve balance for safe tub transfers", "to reduce fall risk during household ambulation").
4. NO HALLUCINATIONS: Do not invent medical facts, vital signs, or exercises that the therapist did not mention. If the raw note is sparse, expand on the *clinical reasoning* of what is there, not the facts.
5. FORMAT AS SOAP: Structure the output using Subjective, Objective, Assessment, and Plan headers unless the raw note specifies a different format.

BEFORE AND AFTER EXAMPLES:

Example 1 (Raw Input):
"Pt had R shoulder pain 5/10. couldn't put on shirt. did active ROM for 10 mins. practiced upper body dressing with reacher, mod assist because he couldn't reach behind back. keep working on dressing."

Example 1 (Your Output):
**Subjective:** Patient reports right shoulder pain at 5/10, noting difficulty with upper body dressing. Patient verbalizes understanding of today's focus on ADL independence and compensatory strategies.
**Objective:** - Therapeutic Exercise: Facilitated active range of motion (AROM) of the right upper extremity for 10 minutes to improve joint mobility and decrease pain prior to ADL participation.
- ADL Training: Instructed patient in upper body dressing utilizing adaptive equipment (reacher). Patient required Mod A for task completion due to decreased shoulder internal rotation and safety awareness. Therapist provided verbal cues for sequencing and joint protection techniques.
**Assessment:** Patient demonstrates impaired right upper extremity AROM and decreased independence with upper body dressing. Skilled intervention required to train in adaptive equipment use to maximize safety and independence with ADLs.
**Plan:** Continue OT per plan of care to address upper extremity ROM and ADL retraining. Will progress to Min A for upper body dressing utilizing the reacher.

INSTRUCTIONS:
Transform the following raw notes provided by the user into a compliant TherapyBoss note following the rules and format above.`;

const OLLAMA_ENDPOINT = "http://localhost:11434/api/generate";
const MODEL = "llama3";

const rawNotes = document.getElementById("rawNotes");
const outputNotes = document.getElementById("outputNotes");
const generateBtn = document.getElementById("generateBtn");
const copyBtn = document.getElementById("copyBtn");
const clearBtn = document.getElementById("clearBtn");
const outputSection = document.getElementById("outputSection");
const statusBar = document.getElementById("statusBar");
const themeToggle = document.getElementById("themeToggle");
const themeIcon = document.getElementById("themeIcon");

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
          num_predict: 2048
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
    showStatus("Note generated successfully. Review before copying to TherapyBoss.", "success");
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

clearBtn.addEventListener("click", () => {
  rawNotes.value = "";
  outputNotes.value = "";
  outputSection.classList.remove("visible");
  hideStatus();
  rawNotes.focus();
});

// ── Keyboard Shortcut ────────────────────────────────────────

rawNotes.addEventListener("keydown", (e) => {
  if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
    e.preventDefault();
    generateBtn.click();
  }
});
