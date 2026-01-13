# Audio Files for Invisible Cost iPad Experience

## Overview

The iPad experience includes full audio support with:
- **Pre-recorded Voice Narration** (recommended for production)
- **Text-to-Speech Fallback** (automatic when no audio files present)
- **Synthesized Sound Effects** (ambient, transitions, sphere sounds)

## How It Works

The `AudioManager` will:
1. First try to load pre-recorded audio files from the app bundle
2. If no audio file is found, fall back to enhanced iOS text-to-speech
3. Sound effects are always synthesized (no files needed)

---

## 🎙️ Creating Professional Narration

### Option 1: AI Voice Generation (Recommended) ⭐

Use AI services to generate realistic voice-overs:

| Service | Quality | Cost | Link |
|---------|---------|------|------|
| **ElevenLabs** | Excellent | ~$5/mo starter | [elevenlabs.io](https://elevenlabs.io) |
| **WellSaid Labs** | Excellent | ~$49/mo | [wellsaidlabs.com](https://wellsaidlabs.com) |
| **Murf AI** | Very Good | ~$29/mo | [murf.ai](https://murf.ai) |
| **Play.ht** | Very Good | Free tier | [play.ht](https://play.ht) |
| **Amazon Polly** | Good | Pay-per-use | AWS Console |

**Recommended voice style:**
- Deep, warm, authoritative male voice OR
- Clear, professional female voice
- Slight dramatic pause between phrases
- Documentary/cinematic tone

### Option 2: Professional Voice Actor

Hire from Fiverr, Voices.com, or Upwork for ~$50-200 total.

### Option 3: Record Yourself

Use a good microphone, quiet room, and audio editing software.

---

## Adding Custom Audio Files

### Narration Files
Add audio files with these exact names (supports .m4a, .mp3, .wav, .aiff):

| Filename | Content |
|----------|---------|
| `narration_opening_1.mp3` | "Every organization carries a hidden cost." |
| `narration_opening_2.mp3` | "Most leaders never see it." |
| `narration_opening_3.mp3` | "You made 247 decisions today. 142 were unnecessary." |
| `narration_vignette_finance.mp3` | "In Finance, reconciliation fatigue consumes hours of skilled attention." |
| `narration_vignette_supply.mp3` | "Supply chain teams drown in manual tracking overhead." |
| `narration_vignette_health.mp3` | "Healthcare professionals spend more time on paperwork than patients." |
| `narration_pattern_break.mp3` | "What if this work... wasn't your work?" |
| `narration_agentic.mp3` | "Agentic orchestration. Intelligence that works while you think." |
| `narration_restoration.mp3` | "Restoration." |
| `narration_human_return.mp3` | "Human potential returned. Reviewing insights. Approving paths." |
| `narration_closing.mp3` | "Agentic automation returns invisible work to the people who matter." |
| `narration_question.mp3` | "What could your organization become?" |

### Ambient Background Music ⭐ IMPORTANT
| Filename | Description |
|----------|-------------|
| `ambient_music.mp3` | **Cinematic ambient music** - loops throughout the experience |

**Requirements:**
- Duration: 2-5 minutes (will loop seamlessly)
- Style: Ethereal pads, subtle tension building to hope, contemplative
- No lyrics, no distracting melodies
- Should feel like a film score underscore

**Recommended Sources:**
- **Artlist.io** - Search "cinematic ambient" or "documentary underscore"
- **Epidemic Sound** - Category: Ambient/Cinematic
- **Pixabay** (Free) - Search "ambient cinematic"
- **Freesound.org** (Free) - Search "ambient pad loop"

**Example Search Terms:**
- "Cinematic ambient tension"
- "Documentary underscore hopeful"
- "Corporate inspiration ambient"
- "Technology ambient futuristic"

### Effect Sounds (Optional - synthesized fallback exists)
| Filename | Description |
|----------|-------------|
| `transition.mp3` | Subtle whoosh/transition sound (~0.5-1s) |
| `reveal.mp3` | Magical reveal/appearance sound (~1-2s) |
| `completion.mp3` | Success/completion chime (~1s) |
| `ui_feedback.mp3` | Soft UI interaction click (~0.2s) |

## Voice Recommendations

For professional narration:
- **Tone**: Calm, authoritative, slightly dramatic
- **Pace**: Slow (around 120 words per minute)
- **Style**: Documentary/TED talk quality
- **Voice**: Deep, warm male or professional female voice
- **Pauses**: Add ~0.5s silence at start and end of each file

---

## Adding Files to Xcode

1. Create an `Audio` folder in your Xcode project
2. Drag all audio files into the folder
3. ✅ Check "Copy items if needed"
4. ✅ Check your iPad target under "Add to targets"
5. Build and run - the app will automatically use your audio files!

### Verify Files Are Bundled
```swift
// Test in your code:
if let url = Bundle.main.url(forResource: "narration_opening_1", withExtension: "m4a") {
    print("✅ Audio file found: \(url)")
}
```

---

## Testing Without Audio Files

The app works perfectly without audio files:
- **Narration**: Falls back to enhanced iOS text-to-speech (tries premium voices first)
- **Sound Effects**: Uses synthesized audio via AVAudioEngine
- **Ambient**: Generates procedural ambient hum

This is useful for development and testing.

---

## Audio Format Recommendations

| Use | Format | Bitrate | Sample Rate | Channels |
|-----|--------|---------|-------------|----------|
| Narration | .m4a or .mp3 | 128-192 kbps | 44.1 kHz | Mono |
| Ambient | .m4a or .mp3 | 128 kbps | 44.1 kHz | Stereo |
| Effects | .m4a or .caf | 128 kbps | 44.1 kHz | Stereo |

---

## Quick Start with ElevenLabs

1. Go to [elevenlabs.io](https://elevenlabs.io) and sign up (free tier available)
2. Choose a voice (try "Adam" for deep male, "Rachel" for professional female)
3. Paste each narrator line and generate
4. Download as MP3
5. Rename files to match the table above (e.g., `narration_opening_1.mp3`)
6. Add to Xcode project
7. Done! 🎉

