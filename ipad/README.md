# The Invisible Cost - Tier 1 (iPad)

This directory contains the spec-true implementation of the Tier 1 experience for Davos 2026.

## Overview
- **Device:** iPad Pro 12.9" (Optimized for ProMotion and Haptics)
- **Runtime:** ~5 minutes
- **Environment:** Standalone SwiftUI App

## Experience Flow
1. **Micro-Cold Open (7s):** Ambient audio and subtle haptic cues.
2. **Narrator Frame (30s):** Cinematic window animations and opening VO.
3. **Human Vignettes (38s):** Emotional flashes for Finance, Supply Chain, and Healthcare.
4. **Pattern Break (30s):** Silence and the pivotal narrative question.
5. **Agentic Orchestration (60s):** Visualization of chaos collapsing into clarity.
6. **Human Return (45s):** Workers restored to potential.
7. **Personalization (60s):** Interactive impact calculator for executives.
8. **Stillness + CTA (30s):** Final message and Vision Pro cross-promotion.

## Implementation Details
- **`ExperienceViewModel.swift`**: Precise state management and timing based on the spec.
- **`NarrativeView.swift`**: Main orchestrator for phases, haptics, and audio.
- **`SubViews/Animations.swift`**: High-fidelity SwiftUI animations for each narrative moment.
- **`AudioManager.swift`**: Centralized audio control for narrator and ambient tracks.

