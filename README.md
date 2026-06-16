# TherapyNote AI Scribe

A local, private AI-powered Chrome Extension for home health occupational therapists. Converts raw shorthand notes into Medicare-compliant SOAP documentation using Ollama — **100% HIPAA compliant, nothing ever leaves the machine.**

## What It Does

1. You type or paste messy shorthand notes into the extension
2. The AI transforms them into a professional, legally defensible Daily Treatment Note
3. You copy the output and paste it into TherapyBoss

**No cloud APIs. No data sent anywhere. Everything runs on your Mac.**

## Example

**Raw input:**
> Pt had R shoulder pain 5/10. couldn't put on shirt. did active ROM for 10 mins. practiced upper body dressing with reacher, mod assist because he couldn't reach behind back.

**Generated output:**
> **Subjective:** Patient reports right shoulder pain at 5/10, noting difficulty with upper body dressing.
> **Objective:** - Therapeutic Exercise: Facilitated active range of motion (AROM) of the right upper extremity for 10 minutes to improve joint mobility and decrease pain prior to ADL participation.
> - ADL Training: Instructed patient in upper body dressing utilizing adaptive equipment (reacher). Patient required Mod A for task completion due to decreased shoulder internal rotation and safety awareness. Therapist provided verbal cues for sequencing and joint protection techniques.
> **Assessment:** Patient demonstrates impaired right upper extremity AROM and decreased independence with upper body dressing. Skilled intervention required to train in adaptive equipment use to maximize safety and independence with ADLs.
> **Plan:** Continue OT per plan of care to address upper extremity ROM and ADL retraining. Will progress to Min A for upper body dressing utilizing the reacher.

---

## Setup Instructions

### 1. Install Ollama

Open Terminal and run:

```bash
brew install ollama
```

If Homebrew isn't installed, download Ollama from https://ollama.com/download instead.

### 2. Download the LLaMA 3 model

In Terminal, run:

```bash
ollama pull llama3
```

This downloads the AI model (~4.7 GB). Only needs to be done once.

### 3. Download this repository

Click the green **Code** button above → **Download ZIP** → unzip it to your Desktop.

Or if you're comfortable with Terminal:

```bash
git clone https://github.com/Mr-Midas/therapy-note-ai-scribe.git ~/therapy-note-ai-scribe
```

### 4. Generate the extension icons

Open Terminal and run:

```bash
cd ~/therapy-note-ai-scribe
pip3 install Pillow
python3 generate_icons.py
```

### 5. Load the extension in Chrome

1. Open Google Chrome
2. Type `chrome://extensions` in the address bar, press Enter
3. Toggle **Developer mode** ON (top-right corner)
4. Click **Load unpacked** (top-left)
5. Select the project folder: `~/therapy-note-ai-scribe`
6. Pin the extension: click puzzle-piece icon → pin "TherapyNote AI Scribe"

### 6. Create the desktop app

Run the setup script in Terminal:

```bash
cd ~/therapy-note-ai-scribe
bash create_app.sh
```

This creates **TherapyNote AI Scribe.app** on your Desktop. Drag it to your Dock for easy access.

---

## Daily Usage

1. Click **TherapyNote AI Scribe** in your Dock
2. Chrome opens with the extension
3. Type or paste your raw notes
4. Click **Generate Compliant Note**
5. Review the output, click **Copy**, paste into TherapyBoss

**Keyboard shortcut:** `Cmd + Enter` in the notes field triggers generation.

> **Note:** The first time you use it each day, it may take 5-10 seconds for Ollama to start. After that, generation takes 2-5 seconds.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| "Cannot connect to Ollama" error | Make sure Ollama is installed. Try opening Terminal and running `ollama serve`, then try again. |
| "Model not found" error | Open Terminal and run `ollama pull llama3` |
| Extension doesn't appear in Chrome | Go to `chrome://extensions` and click the refresh button |
| App icon is missing | Run `python3 generate_icons.py` from the terminal in the project folder |

---

## Privacy & Security

- **Zero cloud calls** — Ollama runs entirely on your local machine
- **No data collection** — the extension has no analytics, telemetry, or tracking
- **No external APIs** — communication is only between the extension and `localhost:11434`
- **HIPAA compliant** — patient data never leaves the device

---

## Requirements

- macOS 11.0 or later
- Google Chrome
- Ollama (free, open-source)
- ~5 GB of free disk space (for Ollama + LLaMA 3 model)

## License

MIT — do whatever you want with it.
