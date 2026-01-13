# Audio-to-Animation Sync Timeline

## The Invisible Cost - iPad Enhanced Experience

**Document Version:** 1.0
**Total Runtime:** ~3:00 (user-paced sections extend this)

---

## Master Sync Timeline

This document specifies exact timing relationships between audio cues and visual animations. All times are relative to phase start unless otherwise noted.

---

## Phase 1: Industry Selection
**Duration:** User-controlled
**Audio File:** `narration_choose_industry.mp3` (3.0s)

| Time | Audio Event | Animation Event | Haptic |
|------|-------------|-----------------|--------|
| 0.00s | Phase enters | Black screen | - |
| 0.20s | Ambient music begins | Particles fade in | - |
| 0.50s | - | Title text fades in | - |
| 1.00s | Narration starts: "Choose your industry" | - | - |
| 1.50s | - | First card appears (Finance) | - |
| 1.65s | - | Second card appears (Supply Chain) | - |
| 1.80s | - | Third card appears (Healthcare) | - |
| 3.00s | Narration ends | Instruction text appears | - |
| [USER TAP] | `sfx_selection` | Selected card pulses, others fade | Medium |

**Animation Details:**
- Cards use `spring(response: 0.6, dampingFraction: 0.8)` for entrance
- Hover state: scale 1.05x, glow radius 20
- Selection: scale 1.1x, glow radius 30, 0.4s duration

---

## Phase 2: Building Tension
**Duration:** 12 seconds
**Audio Files:** `narration_building_{industry}.mp3` (~6s)

| Time | Audio Event | Animation Event | Haptic |
|------|-------------|-----------------|--------|
| 0.00s | Transition whoosh | Scene fade in | - |
| 0.50s | Narration line 1 begins | First text fades in | - |
| 4.00s | Narration line 2 | Second text fades in | - |
| 6.00s | - | Particles accelerate | - |
| 8.00s | - | Teaser metric fades in | - |
| 10.00s | Ambient tension builds | Vignette darkens | - |
| 12.00s | - | Auto-advance to next phase | - |

**Particle Animation:**
- Speed multiplier: `0.15 + progress * 0.3` (accelerates as tension builds)
- Vignette darkens: `0.3 + progress * 0.4` opacity

---

## Phase 3: Industry Vignette
**Duration:** 15 seconds
**Audio Files:** `narration_vignette_{industry}_enhanced.mp3` (~3s)

| Time | Audio Event | Animation Event | Haptic |
|------|-------------|-----------------|--------|
| 0.00s | Transition whoosh | Scene change | - |
| 0.75s | - | Icon scales in from 0.4x to 1.0x | - |
| 1.50s | Narration begins | Title fades in | - |
| 2.25s | - | Subtitle fades in | - |
| 4.50s | Narration ends | - | - |
| 5.25s | `sfx_metric_appear` | Metric 1 appears | Light |
| 6.75s | `sfx_metric_appear` | Metric 2 appears | Light |
| 8.25s | `sfx_metric_appear` | Metric 3 appears | Light |
| 13.00s | Music peaks | Full tension state | - |
| 15.00s | - | Auto-advance | - |

**Icon Animation:**
- Scale: `smoothstep` from 0.4 to 1.0
- Breathing pulse: `1.0 + sin(time * 1.5) * 0.12`

---

## Phase 4: Pattern Break
**Duration:** User-controlled (minimum ~5s for text reveal)
**Audio Files:** `narration_pattern_break_enhanced.mp3` (~5s)

| Time | Audio Event | Animation Event | Haptic |
|------|-------------|-----------------|--------|
| 0.00s | INSTANT SILENCE | White wipe (0.2s) | - |
| 1.50s | - | Hold white | - |
| 1.50s | `sfx_tension_tone` | Low tension tone | - |
| 2.00s | Narration: "But what if..." | Text 1 fades in | - |
| 4.00s | Narration: "...see the real number?" | Text 2 fades in | - |
| 5.00s | `sfx_ready_chime` | Tap indicator appears | - |
| [USER TAP] | `sfx_tap_confirm` | Screen goes black | Medium |

**Critical Timing:**
- The SILENCE after previous phase music is essential
- Hold for 1.5s before any audio
- Text appears with narration cadence

---

## Phase 5: THE SUCKER PUNCH REVEAL
**Duration:** User-controlled (minimum ~12s for full animation)
**Audio Files:** `narration_sucker_punch_{industry}.mp3` (~8s)

### Counter Animation Sequence (4.0 seconds)

| Time | Audio Event | Visual Event | Haptic |
|------|-------------|--------------|--------|
| 0.00s | Silence | Black screen, cursor blink | - |
| 0.50s | `sfx_digit_first` (low tone) | "$4" appears | - |
| 0.75s | Counting begins | "$47" | - |
| 1.00s | `sfx_counting_rapid` loop | "$475" | - |
| 1.25s | Counting accelerates | "$4,750" | - |
| 1.50s | - | "$47,500" | - |
| 2.00s | - | "$475,000" | - |
| 2.50s | - | "$4,750,000" | - |
| 3.50s | - | "$47,500,000" | - |
| 4.00s | `sfx_impact_boom` | FINAL NUMBER + GLOW | HEAVY |

### Post-Counter Sequence

| Time | Audio Event | Visual Event | Haptic |
|------|-------------|--------------|--------|
| 4.50s | Narration begins | Number pulses | - |
| 5.50s | "Forty-seven point five million" | Glow intensifies | - |
| 7.00s | "Every. Single. Year." | Tagline appears | - |
| 8.50s | Narration ends | Full impact state | - |
| 10.00s | `sfx_glow_pulse` | Number breathes | - |
| 12.00s | - | Tap indicator appears | - |
| [USER TAP] | `sfx_card_whoosh` | Transition to comparisons | Light |

**Number Animation Specs:**
```swift
// Counter timing
let totalDuration: Double = 4.0
let steps = 40
let easing = easeOutExpo // Fast at end

// Glow parameters
let glowRadius: CGFloat = 40
let pulseFrequency: Double = 2.0 // Hz
```

---

## Phase 6: Comparison Carousel
**Duration:** User-controlled (3+ cards)
**Audio Files:** `narration_comparison_{industry}_{1-3}.mp3` (~4s each)

### Per-Card Timing

| Time | Audio Event | Visual Event | Haptic |
|------|-------------|--------------|--------|
| 0.00s | `sfx_card_whoosh` | Card slides in from right | Light |
| 0.30s | Card settled | - | - |
| 0.50s | Narration begins | Icon animates | - |
| 2.00s | Number spoken | Number text emphasized | - |
| 3.50s | Emphasis word | Red text pulses | - |
| 4.00s | Narration ends | Ready for next | - |
| [USER TAP] | `sfx_card_whoosh` | Next card or advance | Light |

**Card Animation:**
- Entrance: `offset(x: 50)` to `offset(x: 0)` with `spring(response: 0.4)`
- Exit: `offset(x: -50)` with fade
- Number scaling: `1.0 + sin(time * 1.5) * 0.03`

---

## Phase 7: Agentic Orchestration
**Duration:** 20 seconds
**Audio Files:** `narration_agentic_enhanced.mp3` (~6s)

| Time | Audio Event | Animation Event | Haptic |
|------|-------------|-----------------|--------|
| 0.00s | Music crossfade begins | Sphere container appears | - |
| 0.50s | Upbeat music rises | - | - |
| 1.50s | Crossfade complete | Points begin appearing | - |
| 5.00s | `sfx_sphere_forming` | Connections forming | - |
| 10.00s | - | Connections complete | Soft |
| 12.00s | - | Sphere pulses | - |
| 13.00s | Narration: "This is Agentic Solutions" | Text overlay fades in | - |
| 15.00s | "Intelligence that anticipates" | Tagline appears | - |
| 18.00s | - | Begin exit fade | - |
| 20.00s | - | Auto-advance | - |

**Sphere Animation Phases:**
```swift
let pointsAppear = progress / 0.25           // 0-25%
let connectPhase = (progress - 0.20) / 0.25  // 20-45%
let pulsePhase = (progress - 0.40) / 0.20    // 40-60%
let shrinkPhase = (progress - 0.50) / 0.25   // 50-75%
let textPhase = (progress - 0.65) / 0.20     // 65-85%
```

---

## Phase 8: Automation Anywhere Reveal
**Duration:** 10 seconds
**Audio Files:** `narration_aa_reveal_enhanced.mp3` (~4s)

| Time | Audio Event | Animation Event | Haptic |
|------|-------------|-----------------|--------|
| 0.00s | - | Black screen | - |
| 0.50s | `sfx_reveal` | Halo glow begins | - |
| 1.00s | Narration: "From Automation Anywhere" | Logo fades in | Soft |
| 2.50s | - | Logo fully visible | - |
| 3.50s | "Elevating Human Potential" | Tagline fades in | - |
| 5.00s | Narration ends | - | - |
| 8.00s | - | Begin exit fade | - |
| 10.00s | - | Auto-advance | - |

**Logo Animation:**
- Fade: `smoothstep((progress - 0.05) / 0.20)`
- Halo: pulsing radial gradient with `sin(time * 2) * 0.1` variation

---

## Phase 9: Human Return
**Duration:** 15 seconds
**Audio Files:**
- `narration_restoration_enhanced.mp3` (~3s)
- `narration_breathe.mp3` (~4s)
- `narration_purpose.mp3` (~6s)

| Time | Audio Event | Animation Event | Haptic |
|------|-------------|-----------------|--------|
| 0.00s | `sfx_soft_transition` | Scene transition | - |
| 1.50s | Narration: "The chains dissolve" | Light rays appear | - |
| 4.50s | - | Arcs begin forming | Soft |
| 5.25s | Narration: "And suddenly you remember" | Figure fades in | - |
| 9.00s | Narration: "This is what happens" | Full restoration | - |
| 12.00s | - | Background transitions to white | - |
| 15.00s | - | Auto-advance | - |

**Background Transition:**
- `smoothstep` from black to white over progress 0-1
- Arcs use `spring(response: 0.6)` for organic feel

---

## Phase 10: Call to Action
**Duration:** User-controlled
**Audio Files:** `narration_final_cta_enhanced.mp3` (~5s)

| Time | Audio Event | Animation Event | Haptic |
|------|-------------|-----------------|--------|
| 0.00s | `sfx_completion` | Final scene | - |
| 0.50s | Narration: "The invisible cost..." | Logo pulse begins | - |
| 2.50s | "...ends now" | - | - |
| 3.50s | "The future of work..." | Text appears | - |
| 5.00s | "...starts here" | CTAs fade in | - |
| 9.00s | Music fade begins | - | - |
| 14.00s | Silence | Full CTA state | - |
| [USER TAP] | - | Experience complete | Medium |

---

## Audio File Reference

### Narration Files (Enhanced)
| Filename | Duration | Industry |
|----------|----------|----------|
| narration_choose_industry.mp3 | 3.0s | All |
| narration_building_finance.mp3 | 6.0s | Finance |
| narration_building_supply.mp3 | 6.0s | Supply Chain |
| narration_building_health.mp3 | 5.5s | Healthcare |
| narration_vignette_finance_enhanced.mp3 | 3.5s | Finance |
| narration_vignette_supply_enhanced.mp3 | 2.5s | Supply Chain |
| narration_vignette_health_enhanced.mp3 | 2.5s | Healthcare |
| narration_pattern_break_enhanced.mp3 | 5.0s | All |
| narration_sucker_punch_finance.mp3 | 8.0s | Finance |
| narration_sucker_punch_supply.mp3 | 7.5s | Supply Chain |
| narration_sucker_punch_health.mp3 | 7.5s | Healthcare |
| narration_comparison_finance_1.mp3 | 3.5s | Finance |
| narration_comparison_finance_2.mp3 | 4.0s | Finance |
| narration_comparison_finance_3.mp3 | 4.5s | Finance |
| narration_comparison_supply_1.mp3 | 3.5s | Supply Chain |
| narration_comparison_supply_2.mp3 | 3.5s | Supply Chain |
| narration_comparison_supply_3.mp3 | 2.5s | Supply Chain |
| narration_comparison_health_1.mp3 | 4.0s | Healthcare |
| narration_comparison_health_2.mp3 | 3.5s | Healthcare |
| narration_comparison_health_3.mp3 | 3.0s | Healthcare |
| narration_agentic_enhanced.mp3 | 6.0s | All |
| narration_aa_reveal_enhanced.mp3 | 4.0s | All |
| narration_restoration_enhanced.mp3 | 3.0s | All |
| narration_breathe.mp3 | 4.0s | All |
| narration_purpose.mp3 | 5.5s | All |
| narration_final_cta_enhanced.mp3 | 5.5s | All |

### Sound Effect Files
| Filename | Duration | Usage |
|----------|----------|-------|
| sfx_selection.mp3 | 0.25s | Industry card selection |
| sfx_transition.mp3 | 0.35s | Phase transitions |
| sfx_tension_tone.mp3 | 2.0s | Pattern break |
| sfx_ready_chime.mp3 | 0.5s | Tap indicator |
| sfx_digit_first.mp3 | 0.3s | First digit appear |
| sfx_counting_rapid.mp3 | 0.5s | Counter loop |
| sfx_impact_boom.mp3 | 1.0s | Final number |
| sfx_glow_pulse.mp3 | 0.6s | Number pulse |
| sfx_card_whoosh.mp3 | 0.3s | Comparison cards |
| sfx_sphere_forming.mp3 | 1.5s | Agentic sphere |
| sfx_reveal.mp3 | 0.8s | AA logo reveal |
| sfx_completion.mp3 | 1.0s | Final CTA |

---

## Animation Easing Reference

### Easing Functions Used
```swift
// Smoothstep - used for most transitions
func smoothstep(_ t: Double) -> Double {
    let clamped = min(1.0, max(0, t))
    return clamped * clamped * (3 - 2 * clamped)
}

// EaseOutExpo - used for counter
func easeOutExpo(_ t: Double) -> Double {
    return t == 1 ? 1 : 1 - pow(2, -10 * t)
}

// Spring - used for card animations
Animation.spring(response: 0.4, dampingFraction: 0.8)
Animation.spring(response: 0.6, dampingFraction: 0.75)
```

### Key Duration Constants
```swift
let phaseTransitionDuration: TimeInterval = 1.5
let cardAppearDuration: TimeInterval = 0.6
let numberCountDuration: TimeInterval = 4.0
let glowPulseDuration: TimeInterval = 1.5
let musicCrossfadeDuration: TimeInterval = 1.5
let musicFadeOutDuration: TimeInterval = 8.0
```

---

## Sync Verification Checklist

- [ ] All narration plays within 50ms of visual cue
- [ ] Haptic feedback triggers within 20ms of visual event
- [ ] Counter animation completes in exactly 4.0s
- [ ] Music crossfade is smooth (no gaps or overlaps)
- [ ] User-controlled phases respond within 100ms of tap
- [ ] Phase transitions have no audio pops or clicks
- [ ] 60fps maintained throughout all animations
