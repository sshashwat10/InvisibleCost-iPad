#!/usr/bin/env python3
"""
ElevenLabs Narration Generator for Invisible Cost
==================================================

This script generates all narration audio files using the ElevenLabs API.

Setup:
1. Install the ElevenLabs library:
   pip install elevenlabs

2. Get your API key from https://elevenlabs.io/api
   
3. Set your API key:
   export ELEVENLABS_API_KEY="your-api-key-here"
   
4. Run the script:
   python generate_narration.py

The script will create all audio files in an 'output' folder.
Then drag these files into your Xcode project.
"""

import os
import sys
from pathlib import Path

try:
    from elevenlabs import ElevenLabs, VoiceSettings
except ImportError:
    print("❌ ElevenLabs library not installed!")
    print("   Run: pip install elevenlabs")
    sys.exit(1)

# ============================================================================
# CONFIGURATION
# ============================================================================

# Your ElevenLabs API key (or set via environment variable)
# Set via: export ELEVENLABS_API_KEY="your-key-here"
API_KEY = os.environ.get("ELEVENLABS_API_KEY", "YOUR_API_KEY_HERE")

# Voice ID - "Brian" is great for this, or choose another
# Find voice IDs at: https://elevenlabs.io/voice-library
# Popular options:
#   - Brian (deep, resonant): "nPczCjzI2devNBz1zQrb"
#   - Adam (deep, narrative): "pNInz6obpgDQGcFmaJgB"
#   - Antoni (warm, professional): "ErXwobaYiN019PkySvjV"
#   - Rachel (clear, professional female): "21m00Tcm4TlvDq8ikWAM"
VOICE_ID = "nPczCjzI2devNBz1zQrb"  # Brian

# Model - Eleven Multilingual v2 is recommended
MODEL_ID = "eleven_multilingual_v2"

# Output directory
OUTPUT_DIR = Path("output")

# Voice settings - MORE DRAMATIC & EXPRESSIVE
VOICE_SETTINGS = VoiceSettings(
    stability=0.55,           # More variation for drama
    similarity_boost=0.80,    # Clear voice match
    style=0.65,               # HIGH expressiveness for wow factor
    use_speaker_boost=True    # Enhanced clarity
)

# ============================================================================
# NARRATION LINES - DRAMATIC CINEMATIC VERSION
# ============================================================================
# Using strategic punctuation and phrasing for dramatic effect:
# - Ellipses (...) create natural pauses
# - Periods between phrases add weight
# - Commas control breath and rhythm

NARRATION_LINES = [
    # OPENING - definitive full stops, no pauses between words
    {
        "key": "opening_1",
        "text": "There's something your organization doesn't talk about.",
        "note": "Mysterious, full stop sounds like a full stop"
    },
    {
        "key": "opening_2", 
        "text": "A silent drain on every leader, every team, every single day.",
        "note": "Continuing the thought, building weight"
    },
    {
        "key": "opening_3",
        "text": "Hundreds of decisions that should never have been yours.",
        "note": "Definitive ending - hard full stop"
    },
    
    # VIGNETTES - definitive endings
    {
        "key": "vignette_finance",
        "text": "Hours lost to tasks that machines were made for.",
        "note": "Definitive, hard full stop"
    },
    {
        "key": "vignette_supply",
        "text": "Brilliant minds trapped in busywork.",
        "note": "Tragic, punchy, hard ending"
    },
    {
        "key": "vignette_health",
        "text": "Healers buried under paperwork.",
        "note": "Short and impactful"
    },
    
    # PATTERN BREAK
    {
        "key": "pattern_break",
        "text": "But what if tomorrow looked different?",
        "note": "Hopeful question, smooth flow"
    },
    
    # AGENTIC - clean and powerful
    {
        "key": "agentic",
        "text": "This is Agentic Orchestration. Intelligence that anticipates. Acts. And frees you to think.",
        "note": "Periods create weight on each word"
    },
    
    # HUMAN RETURN - COMPLEMENTS screen text, doesn't read it
    # Screen shows: "RELEASED" / "Rise." / "Your genius awaits."
    # Narration provides emotional context
    {
        "key": "restoration",
        "text": "The chains dissolve. One by one.",
        "note": "Complements 'Released' visual, doesn't read it"
    },
    {
        "key": "human_return",
        "text": "And suddenly you remember what it feels like to breathe.",
        "note": "Emotional complement to 'Rise' visual"
    },
    {
        "key": "potential",
        "text": "This is what happens when machines handle the mechanics and humans reclaim their purpose.",
        "note": "Complements 'Your genius awaits' - provides why"
    },
    
    # CLOSING - COMPLEMENTS screen text, doesn't read it
    # Screen shows: "One decision." / "Infinite possibility." / "Where will you lead?"
    {
        "key": "vision",
        "text": "Picture a world where strategists think bigger. Innovators move faster. Leaders focus on what truly matters.",
        "note": "Rhythmic buildup"
    },
    {
        "key": "closing",
        "text": "When your people are free, everything changes. Innovation accelerates. Sustainability becomes possible. People thrive.",
        "note": "Davos themes as outcomes"
    },
    {
        "key": "proof",
        "text": "This isn't tomorrow. Organizations are living this today.",
        "note": "Urgency - short, punchy"
    },
    {
        "key": "question",
        "text": "With Automationanywhere, you have the power to lead in a world that demands more.",
        "note": "Added 'With' before - comma after forces pause AFTER not during the name"
    },
    {
        "key": "final_cta",
        "text": "The invisible cost ends now.",
        "note": "Simple, powerful, definitive"
    },
]

# ============================================================================
# MAIN SCRIPT
# ============================================================================

def generate_audio(client, text: str, output_path: Path) -> bool:
    """Generate audio for a single line and save to file."""
    try:
        audio_generator = client.text_to_speech.convert(
            voice_id=VOICE_ID,
            model_id=MODEL_ID,
            text=text,
            voice_settings=VOICE_SETTINGS
        )
        
        # Collect all audio chunks
        audio_data = b"".join(audio_generator)
        
        # Write to file
        with open(output_path, "wb") as f:
            f.write(audio_data)
        
        return True
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


def main():
    print("=" * 60)
    print("🎙️  Invisible Cost - Narration Generator")
    print("=" * 60)
    print()
    
    # Check API key
    if API_KEY == "YOUR_API_KEY_HERE":
        print("❌ Please set your ElevenLabs API key!")
        print()
        print("   Option 1: Edit this script and replace YOUR_API_KEY_HERE")
        print("   Option 2: Set environment variable:")
        print("             export ELEVENLABS_API_KEY='your-key-here'")
        print()
        print("   Get your API key at: https://elevenlabs.io/api")
        sys.exit(1)
    
    # Create output directory
    OUTPUT_DIR.mkdir(exist_ok=True)
    print(f"📁 Output directory: {OUTPUT_DIR.absolute()}")
    print()
    
    # Initialize client
    print("🔗 Connecting to ElevenLabs API...")
    client = ElevenLabs(api_key=API_KEY)
    print("   ✅ Connected!")
    print()
    
    # Generate each narration
    print(f"🎬 Generating {len(NARRATION_LINES)} audio files...")
    print("-" * 60)
    
    success_count = 0
    for i, line in enumerate(NARRATION_LINES, 1):
        filename = f"narration_{line['key']}.mp3"
        output_path = OUTPUT_DIR / filename
        
        print(f"\n[{i}/{len(NARRATION_LINES)}] {filename}")
        print(f"   📝 \"{line['text'][:50]}...\"" if len(line['text']) > 50 else f"   📝 \"{line['text']}\"")
        print(f"   🎭 {line['note']}")
        print(f"   ⏳ Generating...", end=" ", flush=True)
        
        if generate_audio(client, line['text'], output_path):
            size_kb = output_path.stat().st_size / 1024
            print(f"✅ Saved ({size_kb:.1f} KB)")
            success_count += 1
        else:
            print("❌ Failed")
    
    # Summary
    print()
    print("=" * 60)
    print(f"✨ Complete! Generated {success_count}/{len(NARRATION_LINES)} files")
    print("=" * 60)
    print()
    print("📋 Next steps:")
    print(f"   1. Open the '{OUTPUT_DIR}' folder")
    print("   2. Drag all .mp3 files into your Xcode project")
    print("   3. Make sure 'Copy items if needed' is checked")
    print("   4. Make sure your iPad target is selected")
    print("   5. Build and run - audio will play automatically!")
    print()
    
    # List generated files
    print("📂 Generated files:")
    for f in sorted(OUTPUT_DIR.glob("narration_*.mp3")):
        print(f"   - {f.name}")


if __name__ == "__main__":
    main()

