#!/usr/bin/env python3
"""
ElevenLabs Sound Effects Generator for Invisible Cost
======================================================

Generates professional sound effects using ElevenLabs Sound Effects API.

Setup:
1. pip install elevenlabs
2. Set your API key: export ELEVENLABS_API_KEY="your-key"
3. Run: python generate_sound_effects.py
"""

import os
import sys
from pathlib import Path

try:
    from elevenlabs import ElevenLabs
except ImportError:
    print("❌ ElevenLabs library not installed!")
    print("   Run: pip install elevenlabs")
    sys.exit(1)

# ============================================================================
# CONFIGURATION
# ============================================================================

API_KEY = os.environ.get("ELEVENLABS_API_KEY", "")

# Output directory
OUTPUT_DIR = Path("../ipad/Resources/Audio")

# ============================================================================
# SOUND EFFECTS - PROFESSIONAL CINEMATIC (Subtle + Key Moments)
# ============================================================================
# Formation sounds: Whisper-quiet, barely perceptible, professional
# Key moments (completion): Warm, emotional, satisfying but not overwhelming

SOUND_EFFECTS = [
    # SUBTLE - Background/Formation sounds (barely there)
    {
        "filename": "sfx_transition.mp3",
        "prompt": "Very soft ambient air movement, like a gentle exhale or quiet breeze through a room, extremely subtle and natural, barely perceptible, professional",
        "duration": 1.0
    },
    {
        "filename": "sfx_reveal.mp3",
        "prompt": "Soft warm ambient tone, like morning light slowly filling a room, gentle and calming, subtle and unobtrusive, professional quality",
        "duration": 2.0
    },
    {
        "filename": "sfx_sphere_forming.mp3",
        "prompt": "Very quiet ambient pad, barely audible low drone, like distant wind or air conditioning hum, extremely subtle background texture, almost silent",
        "duration": 3.0
    },
    {
        "filename": "sfx_dot_appear.mp3",
        "prompt": "Extremely soft barely audible click, like a quiet keyboard tap or distant water drop, almost imperceptible, whisper quiet, fades quickly",
        "duration": 0.5
    },
    {
        "filename": "sfx_line_forming.mp3",
        "prompt": "Very quiet soft woosh, like gentle breath or silk fabric moving, extremely subtle and barely there, whisper level volume",
        "duration": 0.5
    },
    {
        "filename": "sfx_pulse.mp3",
        "prompt": "Extremely quiet low frequency hum, like a distant heartbeat felt more than heard, barely perceptible sub-bass, ambient and unobtrusive",
        "duration": 0.8
    },
    {
        "filename": "sfx_shrink.mp3",
        "prompt": "Very soft descending ambient tone, like air slowly releasing, gentle and quiet, barely noticeable, professional and understated",
        "duration": 1.0
    },
    {
        "filename": "sfx_connection.mp3",
        "prompt": "Extremely quiet soft tick, like a gentle fingertip tap on glass, barely audible, whisper quiet, professional UI sound, quick fade",
        "duration": 0.5
    },
    # KEY MOMENT - Completion (warm, satisfying, but not overwhelming)
    {
        "filename": "sfx_completion.mp3",
        "prompt": "Warm satisfying resolution tone, like a gentle piano chord resolving, hopeful and calming, emotional but understated, professional film quality",
        "duration": 2.0
    },
]

# ============================================================================
# MAIN SCRIPT
# ============================================================================

def generate_sound_effect(client, prompt: str, duration: float, output_path: Path) -> bool:
    """Generate a sound effect using ElevenLabs API."""
    try:
        # Use the sound effects generation endpoint
        result = client.text_to_sound_effects.convert(
            text=prompt,
            duration_seconds=duration
        )
        
        # Collect audio data
        audio_data = b"".join(result)
        
        # Write to file
        with open(output_path, "wb") as f:
            f.write(audio_data)
        
        return True
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


def main():
    print("=" * 60)
    print("🔊 Invisible Cost - Sound Effects Generator")
    print("=" * 60)
    print()
    
    # Check API key
    if not API_KEY:
        print("❌ Please set your ElevenLabs API key!")
        print("   export ELEVENLABS_API_KEY='your-key-here'")
        sys.exit(1)
    
    # Ensure output directory exists
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"📁 Output directory: {OUTPUT_DIR.absolute()}")
    print()
    
    # Initialize client
    print("🔗 Connecting to ElevenLabs API...")
    client = ElevenLabs(api_key=API_KEY)
    print("   ✅ Connected!")
    print()
    
    # Generate each sound effect
    print(f"🎬 Generating {len(SOUND_EFFECTS)} sound effects...")
    print("-" * 60)
    
    success_count = 0
    for i, sfx in enumerate(SOUND_EFFECTS, 1):
        output_path = OUTPUT_DIR / sfx["filename"]
        
        print(f"\n[{i}/{len(SOUND_EFFECTS)}] {sfx['filename']}")
        print(f"   📝 \"{sfx['prompt'][:60]}...\"")
        print(f"   ⏱️  Duration: {sfx['duration']}s")
        print(f"   ⏳ Generating...", end=" ", flush=True)
        
        if generate_sound_effect(client, sfx["prompt"], sfx["duration"], output_path):
            size_kb = output_path.stat().st_size / 1024
            print(f"✅ Saved ({size_kb:.1f} KB)")
            success_count += 1
        else:
            print("❌ Failed")
    
    # Summary
    print()
    print("=" * 60)
    print(f"✨ Complete! Generated {success_count}/{len(SOUND_EFFECTS)} sound effects")
    print("=" * 60)
    print()
    print("📋 Generated files:")
    for sfx in SOUND_EFFECTS:
        path = OUTPUT_DIR / sfx["filename"]
        if path.exists():
            print(f"   ✅ {sfx['filename']}")
        else:
            print(f"   ❌ {sfx['filename']} (failed)")
    print()
    print("🎯 Next: Rebuild your Xcode project to include the new audio files!")


if __name__ == "__main__":
    main()

