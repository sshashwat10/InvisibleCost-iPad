#!/usr/bin/env python3
"""
ElevenLabs Narration Generator for "The Invisible Cost" iPad Experience
Generates all voice narrations using Brian voice with specific settings.

Voice Settings:
- Voice: Brian - Deep, Resonant and Comforting
- Model: Eleven Multilingual v2
- Speed: ~60% (stability param affects this)
- Stability: ~70-75%
- Similarity: ~85-90%
- Style Exaggeration: 0
- Speaker boost: ON
"""

import requests
import os
import json
import time
from pathlib import Path

# ElevenLabs Configuration
API_KEY = "sk_f4770d65bb5fe591558228967a4660abf8e6a897fc32b944"
VOICE_ID = "nPczCjzI2devNBz1zQrb"  # Brian voice ID
MODEL_ID = "eleven_multilingual_v2"

# Voice settings from screenshot
VOICE_SETTINGS = {
    "stability": 0.72,          # ~70-75%
    "similarity_boost": 0.88,    # ~85-90%
    "style": 0.0,                # Style exaggeration: 0
    "use_speaker_boost": True    # Speaker boost: ON
}

# Output directory
OUTPUT_DIR = Path("/Users/shashwatshlok/Projects/InvisibleCost-VisionPro/ipad/Resources/Audio")

# =============================================================================
# NARRATION SCRIPTS
# =============================================================================
# Philosophy: Narrations COMPLEMENT the on-screen text, never duplicate it.
# They add emotional weight, context, and meaning to what users are reading.
# =============================================================================

NARRATIONS = {
    # =========================================================================
    # INDUSTRY SELECTION PHASE
    # On-screen: "THE INVISIBLE COST" / "Choose Your Industry" / "Tap to see your invisible cost"
    # =========================================================================
    "choose_industry":
        "Your industry... your story. "
        "Select the one that mirrors your world, "
        "and we'll show you something... most leaders never see.",

    # =========================================================================
    # BUILDING TENSION PHASE - Industry Specific
    # These play as text appears showing daily operations and teaser metrics
    # =========================================================================

    # FINANCE: On-screen shows "Every report. Every reconciliation." + transaction stats
    "building_finance":
        "Think about your finance team right now. "
        "Hands on keyboards... eyes scanning spreadsheets. "
        "Every reconciliation... every manual entry... "
        "They're doing what's asked of them. "
        "But at what cost? "
        "The kind that never shows up... in a budget.",

    # HEALTHCARE: On-screen shows "Every chart note. Every referral fax." + admin task counts
    "building_health":
        "Your clinicians didn't study for years... to fill out forms. "
        "Yet here they are... charting, authorizing, documenting. "
        "The weight of administration... pressing down... "
        "on people who came to heal.",

    # SUPPLY CHAIN: On-screen shows "Every shipment tracked by hand." + touchpoint counts
    "building_supply":
        "Across your network right now... someone is tracking. "
        "Manually updating. Chasing exceptions. "
        "Every touchpoint... a moment of friction. "
        "Every delay... cascading through your operation... "
        "like a stone dropped into still water.",

    # =========================================================================
    # INDUSTRY VIGNETTE PHASE - Deep Dive
    # Shows industry icon, title, subtitle (e.g., "Reconciliation Fatigue")
    # and metrics like "4.7h daily reconciliation" / "340 manual entries"
    # =========================================================================

    # FINANCE VIGNETTE: Shows "FINANCE" / "Reconciliation Fatigue" / metrics
    "vignette_finance_enhanced":
        "Four and a half hours... every single day. "
        "That's not productivity... that's purgatory.",

    # HEALTHCARE VIGNETTE: Shows "HEALTHCARE" / "Administrative Burden" / metrics
    "vignette_health_enhanced":
        "Five hours of paperwork... for people trained to save lives.",

    # SUPPLY CHAIN VIGNETTE: Shows "SUPPLY CHAIN" / "Inventory Friction" / metrics
    "vignette_supply_enhanced":
        "Three hours of tracking overhead... while your margins erode.",

    # =========================================================================
    # PATTERN BREAK PHASE
    # On-screen: "But what if..." then "you could see the real number?"
    # Then "Tap to reveal" prompt appears
    # =========================================================================
    "pattern_break_enhanced":
        "What if you could see it? "
        "The number no one talks about... "
        "The truth hiding in plain sight.",

    # =========================================================================
    # SUCKER PUNCH REVEAL - THE MOMENT
    # On-screen shows: "YOUR [INDUSTRY]'S INVISIBLE COST" label
    # Then massive animated counter to final amount (e.g., "$47,500,000")
    # Then "EVERY. SINGLE. YEAR." tagline in red
    # =========================================================================

    # FINANCE: Counter lands on $47,500,000
    "sucker_punch_finance":
        "Forty-seven... million... dollars. "
        "Take a moment. "
        "Let that number... settle. "
        "This isn't a projection... this isn't a theory. "
        "This is what's quietly draining from your organization... "
        "every... single... year.",

    # HEALTHCARE: Counter lands on $52,800,000
    "sucker_punch_health":
        "Fifty-two... million... dollars. "
        "Breathe that in. "
        "While your physicians burn out... "
        "while your nurses struggle... "
        "this is the invisible weight... "
        "crushing your organization... every year.",

    # SUPPLY CHAIN: Counter lands on $38,200,000
    "sucker_punch_supply":
        "Thirty-eight... million... dollars. "
        "Feel that. "
        "Not in some abstract report... "
        "but right here... right now. "
        "This is the friction tax... you pay every year.",

    # =========================================================================
    # COMPARISON CAROUSEL - Making the Cost Tangible
    # Shows cards with equivalencies: "950 senior analyst salaries - Gone."
    # =========================================================================

    # FINANCE COMPARISONS
    # Card 1: "950 senior analyst salaries - Gone."
    "comparison_finance_1":
        "Nine hundred and fifty analysts... "
        "who could be driving strategy... instead of chasing spreadsheets.",

    # Card 2: "15 years of your IT budget - Vanished."
    "comparison_finance_2":
        "Fifteen years... of technology investment... gone.",

    # Card 3: "189,000 client meetings - Lost."
    "comparison_finance_3":
        "Nearly two hundred thousand client conversations... "
        "that never happened.",

    # HEALTHCARE COMPARISONS
    # Card 1: "1,056 nurse salaries - Consumed."
    "comparison_health_1":
        "Over a thousand nurses... "
        "consumed by paperwork... instead of patients.",

    # Card 2: "26,400 patient visits - That didn't happen."
    "comparison_health_2":
        "Twenty-six thousand patients... who waited longer than they should.",

    # Card 3: "Your physicians' sanity - Under siege."
    "comparison_health_3":
        "And your physicians... stretched to breaking.",

    # SUPPLY CHAIN COMPARISONS
    # Card 1: "764 warehouse workers - Not hired."
    "comparison_supply_1":
        "Seven hundred workers... you could have hired.",

    # Card 2: "12,700 containers - Delayed."
    "comparison_supply_2":
        "Twelve thousand containers... waiting in limbo.",

    # Card 3: "Your margins. Eroded. Daily."
    "comparison_supply_3":
        "And your margins... slipping away... one delay at a time.",

    # Final carousel card: "Ready to change this?"
    "ready_change":
        "But it doesn't... have to be this way.",

    # =========================================================================
    # AGENTIC ORCHESTRATION PHASE
    # On-screen: 3D sphere of connected nodes forming
    # Then text: "AGENTIC SOLUTIONS" with tagline:
    # "Intelligence that orchestrates. Agents that deliver."
    # =========================================================================
    "agentic_enhanced":
        "Imagine intelligence... that doesn't just respond... "
        "but orchestrates. "
        "Agents that see the whole picture... "
        "that connect what was fragmented... "
        "that deliver... before you even ask.",

    # =========================================================================
    # AUTOMATION ANYWHERE REVEAL
    # On-screen: AA logo fading in with halo glow
    # Then tagline: "Elevating Human Potential" (with 'a' and 'i' in orange)
    # =========================================================================
    "aa_reveal_enhanced":
        "This is Automation Anywhere. "
        "Not replacing human potential... "
        "but elevating it.",

    # =========================================================================
    # HUMAN RETURN / RESTORATION PHASE
    # On-screen: Human silhouette with energy arcs
    # "RESTORATION" label, "Human potential returned."
    # "Reviewing insights. Approving paths."
    # Background transitions from dark to light
    # =========================================================================
    "restoration_enhanced":
        "Now... picture your people... freed.",

    "breathe":
        "Breathe. "
        "This is what's possible.",

    "purpose":
        "Strategy... not spreadsheets. "
        "Innovation... not administration. "
        "Leading... not chasing.",

    # =========================================================================
    # FINAL CTA PHASE
    # On-screen: Pulsing signal/logo, then:
    # "One decision." / "Infinite possibility."
    # "Where will you lead?"
    # CTAs for "EXPERIENCE" (Vision Pro) and "DEMO"
    # =========================================================================
    "final_cta_enhanced":
        "One decision... changes everything. "
        "The invisible cost... doesn't have to stay invisible. "
        "The choice... is yours. "
        "Where will you lead?",
}


def generate_audio(text: str, output_filename: str) -> bool:
    """Generate audio using ElevenLabs API."""

    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}"

    headers = {
        "Accept": "audio/mpeg",
        "Content-Type": "application/json",
        "xi-api-key": API_KEY
    }

    data = {
        "text": text,
        "model_id": MODEL_ID,
        "voice_settings": VOICE_SETTINGS
    }

    try:
        print(f"  Generating: {output_filename}...")
        response = requests.post(url, json=data, headers=headers)

        if response.status_code == 200:
            output_path = OUTPUT_DIR / output_filename
            with open(output_path, 'wb') as f:
                f.write(response.content)
            print(f"    Saved: {output_path}")
            return True
        else:
            print(f"    ERROR {response.status_code}: {response.text}")
            return False

    except Exception as e:
        print(f"    ERROR: {str(e)}")
        return False


def main():
    """Generate all narration audio files."""

    print("=" * 70)
    print("INVISIBLE COST - Narration Audio Generator")
    print("Voice: Brian (Deep, Resonant, Comforting)")
    print("Model: Eleven Multilingual v2")
    print(f"Output: {OUTPUT_DIR}")
    print("=" * 70)
    print()

    # Ensure output directory exists
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    success_count = 0
    fail_count = 0

    total = len(NARRATIONS)

    for i, (key, text) in enumerate(NARRATIONS.items(), 1):
        print(f"\n[{i}/{total}] {key}")
        print(f"  Text: \"{text[:60]}...\"" if len(text) > 60 else f"  Text: \"{text}\"")

        filename = f"narration_{key}.mp3"

        if generate_audio(text, filename):
            success_count += 1
        else:
            fail_count += 1

        # Rate limiting - ElevenLabs allows ~10 requests/second for paid accounts
        # Being conservative with 0.5s delay
        if i < total:
            time.sleep(0.5)

    print()
    print("=" * 70)
    print(f"COMPLETE: {success_count} succeeded, {fail_count} failed")
    print("=" * 70)


if __name__ == "__main__":
    main()
