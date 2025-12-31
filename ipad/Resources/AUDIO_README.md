# Audio Files for Invisible Cost iPad Experience

## Overview

The iPad experience includes full audio support with:
- **Text-to-Speech Narration** (built-in fallback)
- **Ambient Background Sounds**
- **Transition/Effect Sounds**

## How It Works

The `AudioManager` will:
1. First try to load pre-recorded audio files from the app bundle
2. If no audio file is found, fall back to synthesized speech (for narration) or silent operation (for effects)

## Adding Custom Audio Files

To add professional narration and sound effects, add these files to your Xcode project:

### Narration Files
Add MP3 files with these exact names:

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

### Ambient Sound
| Filename | Description |
|----------|-------------|
| `ambient_hum.mp3` | Looping office ambience - soft typing, subtle notifications, gentle keyboard sounds |

### Effect Sounds
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

## Adding Files to Xcode

1. Create a `Resources` folder in your Xcode project (if not exists)
2. Drag audio files into the folder
3. Ensure "Copy items if needed" is checked
4. Ensure target membership includes `InvisibleCost-iPad`

## Testing Without Audio Files

The app will work without any audio files - it will use iOS text-to-speech for narration and simply log effect sounds to the console. This is useful for development and testing.

## Audio Format Recommendations

- **Format**: MP3 or AAC
- **Bitrate**: 128-256 kbps
- **Sample Rate**: 44.1 kHz
- **Channels**: Stereo (for ambient), Mono (for narration)

