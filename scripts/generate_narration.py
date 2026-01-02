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
    # OPENING - each line FLOWS into the next with trailing/connecting tone
    {
        "key": "opening_1",
        "text": "There's something your organization doesn't talk about.",
        "note": "Mysterious, trailing tone that invites continuation"
    },
    {
        "key": "opening_2", 
        "text": "A silent drain on every leader, every team, every single day.",
        "note": "Continuing the thought, building weight"
    },
    {
        "key": "opening_3",
        "text": "Hundreds of decisions... that shouldn't have been yours to make.",
        "note": "Personal revelation, pause before 'that'"
    },
    
    # VIGNETTES - connected narrative, same emotional thread
    {
        "key": "vignette_finance",
        "text": "Hours vanishing... into tasks that machines were built for.",
        "note": "Empathetic, slight pause after vanishing"
    },
    {
        "key": "vignette_supply",
        "text": "Brilliant minds... buried in busywork.",
        "note": "Tragic waste, weight on 'buried'"
    },
    {
        "key": "vignette_health",
        "text": "Healers... drowning in paperwork instead of patients.",
        "note": "Sorrowful injustice"
    },
    
    # PATTERN BREAK - the pivot, hope emerges
    {
        "key": "pattern_break",
        "text": "But what if... tomorrow looked different?",
        "note": "Hopeful shift, questioning, possibility opens"
    },
    
    # AGENTIC - MUST include 'Agentic Orchestration' term
    {
        "key": "agentic",
        "text": "This is Agentic Orchestration. Intelligence that anticipates... that acts... and frees you to think.",
        "note": "Powerful declaration, term spoken clearly, then flowing description"
    },
    
    # HUMAN RETURN - emotional relief, LONGER for animation sync
    {
        "key": "restoration",
        "text": "And just like that... the weight begins to lift.",
        "note": "Relief washing over, gentle, connected to next"
    },
    {
        "key": "human_return",
        "text": "The noise fades... clarity returns... and you remember... why you started.",
        "note": "Emotional journey home, each phrase lands, satisfying conclusion"
    },
    
    # CLOSING - powerful, thought-provoking, unforgettable ending
    {
        "key": "closing",
        "text": "Imagine your brightest minds... unchained from the mundane. Strategists strategizing. Innovators innovating. Leaders... actually leading.",
        "note": "Paint the vision with rhythmic power, build momentum, pause before 'actually leading'"
    },
    {
        "key": "question",
        "text": "The invisible cost has been paid for far too long. With Automation Anywhere... the future of work isn't a question... it's already here. The only question is: are you ready to lead it?",
        "note": "POWERFUL CLOSER - weight on 'far too long', Automation Anywhere spoken clearly with pride, ends with direct challenge"
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

