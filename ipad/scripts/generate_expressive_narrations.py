#!/usr/bin/env python3
"""
ElevenLabs EXPRESSIVE Narration Generator for "The Invisible Cost" iPad Experience
Generates all voice narrations with SNAPPY, PUNCHY delivery.

UPDATED: January 2026 - Department-based system (P2P, O2C, Customer Support, ITSM)
KEY PRINCIPLE: Narrations are GENERAL - NO specific numbers in audio, numbers shown VISUALLY

Voice Settings OPTIMIZED FOR EXPRESSIVENESS:
- Voice: Brian - Deep, Resonant and Comforting
- Model: Eleven Multilingual v2
- Stability: 0.35 (LOW for more expressiveness and variation)
- Similarity: 0.80 (balanced for natural delivery)
- Style Exaggeration: 0.15 (slight emphasis)
- Speaker boost: ON

PAUSE FORMATTING: Use "..." DIRECTLY after words with NO space before.
Example: "incredible..." NOT "incredible ..."
"""

import requests
import os
import json
import time
from pathlib import Path

# ElevenLabs Configuration
API_KEY = "sk_b9647331ac60e95fa82c81e0bca8ab69d609ed46633db2b4"
VOICE_ID = "nPczCjzI2devNBz1zQrb"  # Brian voice ID
MODEL_ID = "eleven_multilingual_v2"

# Voice settings OPTIMIZED FOR EXPRESSIVENESS
# Lower stability = more expressive, more variation in delivery
# This creates a more engaging, dynamic narration
VOICE_SETTINGS = {
    "stability": 0.35,            # LOW for expressiveness (was 0.72)
    "similarity_boost": 0.80,     # Balanced (was 0.88)
    "style": 0.15,                # Slight style for emphasis (was 0.0)
    "use_speaker_boost": True     # Speaker boost: ON
}

# Output directory - directly to main Audio folder
OUTPUT_DIR = Path("/Users/shashwatshlok/Projects/InvisibleCost-VisionPro/ipad/Resources/Audio")

# =============================================================================
# EXPRESSIVE NARRATION SCRIPTS - SNAPPY AND PUNCHY
# =============================================================================
# Key principles:
# 1. Use "..." directly after words for pauses (no space before)
# 2. Keep sentences SHORT and punchy
# 3. Remove unnecessary words - every word must earn its place
# 4. Create rhythm through strategic pauses
# 5. End with impact
# 6. NO SPECIFIC NUMBERS in audio - numbers are shown visually on screen
# 7. All claims must be SOURCED (Forrester TEI, APQC, Ardent Partners, etc.)
# =============================================================================

NARRATIONS = {
    # =========================================================================
    # EMOTIONAL INTRO - Per Neeti's edit (Jan 2026)
    # =========================================================================
    "opening_1":
        "Every organization carries a hidden cost. Repetitive work. Manual processes. Lost time. "
        "And it's costing more than most leaders realize.",

    "opening_2":
        "Most leaders never quantify it. Until now.",

    # =========================================================================
    # DEPARTMENT SELECTION - Per Neeti's edit
    # =========================================================================
    "choose_department":
        "Choose a department and we will illustrate with an example.",

    "choose_industry":
        "Choose a department and we will illustrate with an example.",

    # =========================================================================
    # DEPARTMENT INPUT - Per Neeti's edit
    # =========================================================================
    "department_input":
        "Input your parameters to use industry benchmarks and calculate potential hidden costs.",

    "personal_input":
        "Input your parameters to use industry benchmarks and calculate potential hidden costs.",

    # =========================================================================
    # BUILDING TENSION - Department Specific - Clinical and factual
    # =========================================================================

    # P2P (Procure-to-Pay)
    "building_p2p":
        "Invoice processing. Every invoice requires matching... verification... approval. "
        "Your team executes this workflow thousands of times annually. Industry data reveals the true cost.",

    # O2C (Order-to-Cash)
    "building_o2c":
        "Order to cash. Every order requires processing... credit verification... invoicing... collection. "
        "Each step introduces latency. Industry data reveals the true cost.",

    # Customer Support
    "building_customer_support":
        "Customer support. Every ticket requires intake... lookup... resolution. "
        "The same inquiries, processed repeatedly. Industry data reveals the true cost.",

    # ITSM
    "building_itsm":
        "IT service management. Every request requires triage... assignment... resolution. "
        "Password resets alone consume significant capacity. Industry data reveals the true cost.",

    # Legacy
    "building_finance":
        "Finance operations. Every transaction requires entry... reconciliation... approval. "
        "Your team executes this workflow thousands of times annually. Industry data reveals the true cost.",

    "building_health":
        "Clinical administration. Every patient requires charting... authorization... documentation. "
        "Time diverted from patient care. Industry data reveals the true cost.",

    "building_supply":
        "Supply chain operations. Every shipment requires tracking... updating... exception handling. "
        "Manual touchpoints at every stage. Industry data reveals the true cost.",

    # =========================================================================
    # DEPARTMENT VIGNETTE - Clinical observations
    # =========================================================================

    "vignette_p2p_enhanced":
        "Invoices accumulating. Cash flow constrained. Teams consumed by manual processing.",

    "vignette_o2c_enhanced":
        "Orders queued. Revenue delayed. Collection cycles extending.",

    "vignette_customer_support_enhanced":
        "Tickets accumulating. Response times lengthening. Agents repeating the same resolutions.",

    "vignette_itsm_enhanced":
        "Requests pending. Users waiting. Technical staff consumed by routine tasks.",

    "vignette_finance_enhanced":
        "Transactions queued. Reconciliations pending. Analysts consumed by data entry.",

    "vignette_health_enhanced":
        "Documentation backlog. Authorizations pending. Clinical staff consumed by paperwork.",

    "vignette_supply_enhanced":
        "Shipments tracked manually. Exceptions mounting. Visibility degrading.",

    # =========================================================================
    # PATTERN BREAK - Clinical question
    # =========================================================================
    "pattern_break_enhanced":
        "What is the true operational cost?",

    # =========================================================================
    # SUCKER PUNCH REVEAL - Clinical statement
    # =========================================================================
    "sucker_punch_reveal":
        "This... is your invisible cost. Annually. Exposed.",

    "sucker_punch_finance":
        "This is what manual operations cost you. Annually. Exposed.",

    "sucker_punch_health":
        "This is what administrative burden costs you. Annually. Exposed.",

    "sucker_punch_supply":
        "This is what manual processes cost you. Annually. Exposed.",

    # =========================================================================
    # COST BREAKDOWN - Clinical explanation
    # =========================================================================
    "cost_breakdown":
        "Direct labor costs. Overhead allocation. And the hidden factors... exceptions, rework, opportunity cost.",

    # =========================================================================
    # COMPARISON CAROUSEL - Clinical statements
    # =========================================================================

    # P2P
    "comparison_p2p_1":
        "Full-time employees allocated entirely to manual processing.",

    "comparison_p2p_2":
        "Budget capacity redirected from strategic initiatives.",

    "comparison_p2p_3":
        "Productive hours consumed by repetitive manual tasks.",

    # O2C
    "comparison_o2c_1":
        "Revenue held in accounts receivable.",

    "comparison_o2c_2":
        "Working capital unavailable for operations.",

    "comparison_o2c_3":
        "Work weeks consumed by manual collection processes.",

    # Customer Support
    "comparison_customer_support_1":
        "Agent capacity consumed by routine inquiries.",

    "comparison_customer_support_2":
        "Hours spent on questions automation could resolve.",

    "comparison_customer_support_3":
        "Customer wait time that erodes satisfaction.",

    # ITSM
    "comparison_itsm_1":
        "Cost of password resets alone.",

    "comparison_itsm_2":
        "User productivity lost waiting for IT resolution.",

    "comparison_itsm_3":
        "Technical staff time consumed by tier-one tickets.",

    # Legacy
    "comparison_finance_1":
        "Analyst capacity consumed by manual data entry.",

    "comparison_finance_2":
        "Budget equivalent redirected from growth initiatives.",

    "comparison_finance_3":
        "Productive hours lost to reconciliation tasks.",

    "comparison_health_1":
        "Clinical staff time consumed by documentation.",

    "comparison_health_2":
        "Patient encounters that could have occurred.",

    "comparison_health_3":
        "Care capacity lost to administrative burden.",

    "comparison_supply_1":
        "Positions unfilled due to budget constraints.",

    "comparison_supply_2":
        "Shipments delayed by manual processing.",

    "comparison_supply_3":
        "Margin erosion from operational inefficiency.",

    # Transition
    "ready_change":
        "Ready to recover this capacity?",

    # =========================================================================
    # AGENTIC ORCHESTRATION - Clinical explanation
    # =========================================================================
    "agentic_enhanced":
        "Now consider: automation that operates across your entire system. "
        "AI agents that identify work, execute processes, and resolve issues... before escalation.",

    # =========================================================================
    # AUTOMATION ANYWHERE REVEAL - Clinical credibility
    # =========================================================================
    "aa_reveal_forrester":
        "Automation Anywhere. Industry-leading ROI. Fastest payback in the category. "
        "Validated by Forrester Total Economic Impact.",

    "aa_reveal_enhanced":
        "Automation Anywhere.",

    # =========================================================================
    # AA VALUE PROPOSITION - Department Specific - Clinical benefits
    # =========================================================================
    "aa_value_p2p":
        "Touchless invoice processing. Straight-through matching. Exception handling automated. "
        "Your team reallocated to strategic finance.",

    "aa_value_o2c":
        "Accelerated collections. Compressed cycle times. Cash flow optimized.",

    "aa_value_customer_support":
        "Faster resolution. Higher satisfaction. Agents focused on complex cases that require human judgment.",

    "aa_value_itsm":
        "Instant provisioning. Automated resolution. IT talent redirected to strategic initiatives.",

    # =========================================================================
    # HUMAN RETURN / RESTORATION - Clinical outcome
    # =========================================================================
    "restoration_enhanced":
        "Manual work... automated. Repetitive processes... eliminated. Capacity... restored.",

    "breathe":
        "This is what operational efficiency looks like.",

    "purpose":
        "Strategy instead of spreadsheets. Innovation instead of administration. Leading instead of processing.",

    # =========================================================================
    # FINAL CTA - Per Neeti's edit
    # =========================================================================
    "final_cta_enhanced":
        "Say no to invisible costs. The question is: what will you do with the capacity you recover?",
}


def generate_audio(text: str, output_filename: str) -> bool:
    """Generate audio using ElevenLabs API with expressive settings."""

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
        response = requests.post(url, json=data, headers=headers, timeout=60)

        if response.status_code == 200:
            output_path = OUTPUT_DIR / output_filename
            with open(output_path, 'wb') as f:
                f.write(response.content)

            # Get file size for reference
            file_size = os.path.getsize(output_path)
            print(f"    Saved: {output_path} ({file_size:,} bytes)")
            return True
        else:
            print(f"    ERROR {response.status_code}: {response.text}")
            return False

    except Exception as e:
        print(f"    ERROR: {str(e)}")
        return False


def main():
    """Generate all expressive narration audio files."""

    print("=" * 70)
    print("INVISIBLE COST - EXPRESSIVE Narration Audio Generator")
    print("=" * 70)
    print("Voice: Brian (Deep, Resonant, Comforting)")
    print("Model: Eleven Multilingual v2")
    print("Settings: EXPRESSIVE (stability=0.35, similarity=0.80, style=0.15)")
    print(f"Output: {OUTPUT_DIR}")
    print("=" * 70)
    print()
    print("KEY PRINCIPLE: Narrations are GENERAL - NO specific numbers in audio")
    print("Numbers are shown VISUALLY on screen with counting animations")
    print("=" * 70)
    print()

    # Ensure output directory exists
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    success_count = 0
    fail_count = 0

    total = len(NARRATIONS)

    for i, (key, text) in enumerate(NARRATIONS.items(), 1):
        print(f"\n[{i}/{total}] {key}")
        print(f"  Text: \"{text[:70]}...\"" if len(text) > 70 else f"  Text: \"{text}\"")

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
    print()
    print("Next steps:")
    print("1. Test audio files in app")
    print("2. Update AudioManager.swift estimated durations if needed")
    print("3. Adjust phase timing based on actual audio lengths")
    print()
    print("NEW NARRATIONS ADDED:")
    print("- choose_department, department_input")
    print("- building_p2p, building_o2c, building_customer_support, building_itsm")
    print("- vignette_p2p_enhanced, vignette_o2c_enhanced, etc.")
    print("- sucker_punch_reveal (general, no numbers)")
    print("- cost_breakdown")
    print("- comparison_p2p_*, comparison_o2c_*, etc.")
    print("- aa_reveal_forrester, aa_value_p2p, aa_value_o2c, etc.")


if __name__ == "__main__":
    main()
