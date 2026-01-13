#!/usr/bin/env python3
"""
ElevenLabs Audio Generation Script for The Invisible Cost iPad Experience
Generates all narration audio files with consistent voice and styling.
"""

import os
import requests
import json
import time
from pathlib import Path

# ElevenLabs API Configuration
API_KEY = "sk_f4770d65bb5fe591558228967a4660abf8e6a897fc32b944"
BASE_URL = "https://api.elevenlabs.io/v1"

# Output directory
OUTPUT_DIR = Path(__file__).parent.parent / "Resources" / "Audio" / "enhanced"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Voice settings for professional, authoritative narration
# Using "Adam" voice - deep, professional male
VOICE_ID = "pNInz6obpgDQGcFmaJgB"  # Adam - professional male voice

# Alternative voices if Adam isn't available:
# "21m00Tcm4TlvDq8ikWAM" - Rachel (professional female)
# "ErXwobaYiN019PkySvjV" - Antoni (confident male)
# "EXAVITQu4vr4xnSDxMaL" - Bella (warm female)

VOICE_SETTINGS = {
    "stability": 0.75,           # Higher = more consistent
    "similarity_boost": 0.85,    # Higher = more similar to original voice
    "style": 0.1,                # Lower = more neutral
    "use_speaker_boost": True
}

# Model to use
MODEL_ID = "eleven_multilingual_v2"

# All narration scripts organized by phase
NARRATION_SCRIPTS = {
    # Industry Selection
    "narration_choose_industry": "Choose your industry. See your invisible cost.",

    # Building Tension - by industry
    "narration_building_finance": "Every report. Every reconciliation. Every manual entry that keeps your team from the work that matters.",
    "narration_building_supply": "Every shipment tracked by hand. Every exception managed manually. Every delay cascading through your network.",
    "narration_building_health": "Every chart note. Every referral fax. Every authorization that keeps healers from healing.",

    # Industry Vignettes
    "narration_vignette_finance_enhanced": "Hours lost to tasks that machines were made for.",
    "narration_vignette_supply_enhanced": "Brilliant minds trapped in busywork.",
    "narration_vignette_health_enhanced": "Healers buried under paperwork.",

    # Pattern Break
    "narration_pattern_break_enhanced": "But what if... you could see the real number?",

    # THE SUCKER PUNCH - by industry
    "narration_sucker_punch_finance": "Forty-seven point five million dollars. Every. Single. Year. Gone. To invisible work.",
    "narration_sucker_punch_supply": "Thirty-eight point two million dollars. Every. Single. Year. Evaporating. While you watch.",
    "narration_sucker_punch_health": "Fifty-two point eight million dollars. Every. Single. Year. Stolen. From patient care.",

    # Comparison lines - Finance
    "narration_comparison_finance_1": "That's nine hundred fifty senior analyst salaries. Gone.",
    "narration_comparison_finance_2": "Fifteen years of your entire IT budget. Vanished.",
    "narration_comparison_finance_3": "A hundred eighty-nine thousand client meetings. Lost.",

    # Comparison lines - Supply Chain
    "narration_comparison_supply_1": "That's seven hundred sixty-four warehouse workers. Not hired.",
    "narration_comparison_supply_2": "Twelve thousand seven hundred containers. Delayed.",
    "narration_comparison_supply_3": "Your margins. Eroded. Daily.",

    # Comparison lines - Healthcare
    "narration_comparison_health_1": "That's over a thousand nurse salaries. Consumed by paperwork.",
    "narration_comparison_health_2": "Twenty-six thousand patient visits. That didn't happen.",
    "narration_comparison_health_3": "Your physicians' sanity. Under siege.",

    # Agentic Solution
    "narration_agentic_enhanced": "This is Agentic Solutions. Intelligence that anticipates. Acts. And frees you to think.",

    # AA Reveal
    "narration_aa_reveal_enhanced": "From Automation Anywhere. Elevating Human Potential.",

    # Human Return
    "narration_restoration_enhanced": "The chains dissolve. One by one.",
    "narration_breathe": "And suddenly you remember what it feels like to breathe.",
    "narration_purpose": "This is what happens when machines handle the mechanics and humans reclaim their purpose.",

    # Final CTA
    "narration_final_cta_enhanced": "The invisible cost... ends now. The future of work... starts here.",

    # Ready to change prompt
    "narration_ready_change": "Ready to change this?",
}


def get_available_voices():
    """Fetch available voices from ElevenLabs API."""
    headers = {"xi-api-key": API_KEY}
    response = requests.get(f"{BASE_URL}/voices", headers=headers)
    if response.status_code == 200:
        voices = response.json().get("voices", [])
        print("Available voices:")
        for voice in voices:
            print(f"  - {voice['name']}: {voice['voice_id']}")
        return voices
    else:
        print(f"Failed to get voices: {response.status_code}")
        return []


def generate_audio(text: str, filename: str, voice_id: str = VOICE_ID) -> bool:
    """Generate audio file from text using ElevenLabs API."""

    url = f"{BASE_URL}/text-to-speech/{voice_id}"

    headers = {
        "xi-api-key": API_KEY,
        "Content-Type": "application/json",
        "Accept": "audio/mpeg"
    }

    data = {
        "text": text,
        "model_id": MODEL_ID,
        "voice_settings": VOICE_SETTINGS
    }

    print(f"Generating: {filename}")
    print(f"  Text: \"{text[:50]}...\"" if len(text) > 50 else f"  Text: \"{text}\"")

    try:
        response = requests.post(url, headers=headers, json=data, timeout=30)

        if response.status_code == 200:
            output_path = OUTPUT_DIR / f"{filename}.mp3"
            with open(output_path, "wb") as f:
                f.write(response.content)
            print(f"  Success: Saved to {output_path}")
            return True
        else:
            print(f"  Error: {response.status_code} - {response.text[:200]}")
            return False

    except requests.exceptions.RequestException as e:
        print(f"  Request failed: {e}")
        return False


def main():
    """Generate all narration audio files."""
    print("=" * 60)
    print("The Invisible Cost - Audio Generation")
    print("=" * 60)
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Voice ID: {VOICE_ID}")
    print(f"Total files to generate: {len(NARRATION_SCRIPTS)}")
    print()

    # First, verify API connection
    print("Verifying ElevenLabs API connection...")
    headers = {"xi-api-key": API_KEY}
    try:
        response = requests.get(f"{BASE_URL}/user", headers=headers, timeout=10)
        if response.status_code == 200:
            user_info = response.json()
            print(f"  Connected as: {user_info.get('subscription', {}).get('tier', 'Unknown')}")
            character_count = user_info.get('subscription', {}).get('character_count', 0)
            character_limit = user_info.get('subscription', {}).get('character_limit', 0)
            print(f"  Characters used: {character_count}/{character_limit}")
        else:
            print(f"  Warning: Could not verify connection ({response.status_code})")
    except Exception as e:
        print(f"  Warning: Connection check failed: {e}")

    print()
    print("Starting audio generation...")
    print("-" * 60)

    success_count = 0
    fail_count = 0

    for filename, text in NARRATION_SCRIPTS.items():
        success = generate_audio(text, filename)
        if success:
            success_count += 1
        else:
            fail_count += 1

        # Rate limiting - wait between requests
        time.sleep(0.5)

    print()
    print("=" * 60)
    print("Generation Complete")
    print(f"  Successful: {success_count}/{len(NARRATION_SCRIPTS)}")
    print(f"  Failed: {fail_count}/{len(NARRATION_SCRIPTS)}")
    print(f"  Output: {OUTPUT_DIR}")
    print("=" * 60)


if __name__ == "__main__":
    main()
