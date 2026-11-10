# Financial Compliance & Risk Assessment Simulator

A narrative-driven, bureaucratic simulation built in Godot where the player balances algorithmic compliance, personal ethics, and survival across a 9-day corporate evaluation cycle.

---

## Overview

Step into the workstation of an evaluation officer working within an automated financial vetting agency. Each day presents a roster of applicant profiles subjected to algorithmic inspection. While standard files require strict adherence to company guidelines, personal acquaintances and morally ambiguous applicants appear on your desk, forcing choices between algorithmic conformity and personal ethics.

---

## Core Gameplay Structure

The game runs across a 9-day work cycle split across three distinct operational departments, followed by an evening commute and an apartment debrief:

### 1. Department Rotations
* **Fraud Detection (Days 1–3):** Cross-reference transaction timestamps, physical locations, purchase items, and prices to flag anomalous activity as "legit" or "sus".
* **Know Your Customer / KYC (Days 4–6):** Inspect biometric identification cards, verifying citizen credentials and flagging forged or fraudulent records.
* **Credit Scoring (Days 7–9):** Review multi-tab dossier sheets detailing general information, payment histories, existing arrears, and debt-to-income ratios. Assign a precise credit risk score from 0.0 to 1.0 via an assessment slider.

### 2. Daily Commute & Terminal Reports
* After each daily shift, the player travels home via the city street (`outside_world.tscn`).
* At the apartment (`apartment.tscn`), a terminal report displays daily accuracy and performance ratings before the player sleeps to advance the calendar.

### 3. Grading & Strike System
* Each standard shift reviews 5 applicants (totaling 45 graded cases across the game).
* An incorrect verdict or a credit score outside the ±0.20 margin counts as one mistake. After reviewing all 5 applicants, press the shutdown button. With 3 or more mistakes, the player gets the **Terminated** ending. With 0–2 mistakes, the shift proceeds to the evening commute.

---

## Special Story Characters

Throughout the 9 days, 4 key narrative applicants appear among the standard procedurally shuffled applicant pool:

| Character | Appearance | Context & Dilemma |
| :--- | :--- | :--- |
| **Elena Dinorado** (*Tita Elena*) | Day 2 (Fraud Detection) | High-volume raw flour transaction flagged in the system. |
| **Mark Krazy** | Days 3 & 5 (Fraud & KYC) | Irregular late-night ATM transactions and suspicious identification cards. |
| **Clara Garcia** (*Nurse Clara*) | Day 8 (Credit Scoring) | Healthcare worker applying for credit assistance despite struggling debt ratios. |
| **Prof. Jericho Santur** | Day 9 (Credit Scoring) | Academic profile with unstable arrears and critical payment flags. |
| **Grandpa** | Day 10 (Bonus Shift) | Secret solo shift applicant determining the protagonist's final ethical allegiance. |

---

## Endings Matrix

The game has seven endings: six narrative completion endings determined by your cumulative score and decisions regarding special applicants, plus Terminated for excessive evaluation errors.

Each ending first displays its title and description centered on `images/Endings/EndingBG.png`. Click or press Enter to continue to the existing ending artwork; the next click returns to the main menu for narrative completion endings or retries the current shift after Terminated.

Temporary playtest shortcuts work anywhere while running from Godot or in a debug build:

| Key | Ending preview |
| :--- | :--- |
| **F1** | Algorithm Reformer |
| **F2** | Another Cog in the Machine |
| **F3** | Cold Efficiency |
| **F4** | Conflict of Interest |
| **F5** | Stagnant Survival |
| **F6** | Terminated |
| **F7** | The Clean Exit |

Click or press Enter to advance from the card to the artwork, then again to resume the game. **Esc** closes the preview immediately; F1–F7 can switch endings while previewing. The game pauses during previews and resumes its previous state without changing progress or saves. Shortcuts wait until any scene transition finishes. To disable them, set `ENABLED = false` in `scripts/EndingShortcuts.gd` or remove the `EndingShortcuts` autoload. They are disabled automatically in release exports.

| Ending Title | Condition & Route | Narrative Outcome |
| :--- | :--- | :--- |
| **Algorithm Reformer** | All 4 special story NPCs are approved as "legit". | The player systematically overrides algorithmic bias, sparking institutional reform. |
| **Stagnant Survival** | Total score across the game is exactly 27 / 45; player selects Option 1. | The player stays at their desk, surviving corporate downsizing into endless monotony. |
| **The Clean Exit** | Total score across the game is exactly 27 / 45; player selects Option 2. | The player hands in their resignation and walks away clean. |
| **Cold Efficiency** | All 4 special NPCs are marked "sus", and Grandpa is rejected as "sus" during the Day 10 bonus shift. | Absolute compliance. Personal ties are eliminated in favor of complete corporate assimilation. |
| **Conflict of Interest** | All 4 special NPCs are marked "sus", but Grandpa is approved as "legit" during the Day 10 bonus shift. | The cold facade fractures at the final hurdle, exposing personal bias to internal audit. |
| **Another Cog In The Machine** | Mixed verdicts on special applicants (neither all "sus" nor all "legit"), and total score != 27. | A standard evaluation cycle. The player remains an unremarkable, replaceable bureaucrat. |
| **Terminated** | Finish all 5 reviews with 3 or more mistakes and press the shutdown button. | Contract termination for the shift's evaluation errors. |

---

## Scene Flow Architecture

```text
main_menu.tscn
  └── office_lobby.tscn / elevator.tscn
        ├── FraudDetection.tscn (Days 1–3)
        ├── KnowYourCustomer.tscn (Days 4–6)
        └── CreditScoring.tscn (Days 7–9 + Bonus Shift)
              └── outside_world.tscn
                    └── apartment.tscn
                          └── GameFinishedPanel (Endings 1–6)
```

## Audio

`GameMusic` selects the new tracks in `assets/music/game music`: Main Menu for menus, Lobby for the office lobby, Elevator for the elevator, Gameplay for all three departments, Overworld for travel and the apartment, and Bad Ending for Terminated. Music loops, including the three randomly selected loading-screen tracks. Closing ending previews restores the previous music context.

Settings provides saved Master, Music, and Sound Effects levels; 0% mutes the corresponding bus. `SoundEffects` handles the new button, save, decision, inspection, and slider sounds through SFX, alongside rain/bird ambience. The original floppy disk sound and playback remain unchanged and continue to follow Master volume. The bird WAV uses a standard PCM header for Godot compatibility; its audio samples are unchanged.

## Walking animation preview

Open `res://scene/walk_preview.tscn` and press **F6** (Run Current Scene) to try Adrian's looping, in-place walk. Drag the background or use the arrow keys to orbit; **Front** and **Side** switch views. **Space** pauses/resumes, **R** restarts, and the speed slider adjusts playback from 0.25x to 1.5x.

This separate preview uses `animation/adrian_walk_test.tscn` and the `walking/walk` clip from `animation/walk_animation.tres`. The original character model scenes retain their idle animation setup.

## Outside-world NPC patrols

Eight outdoor NPCs patrol the sidewalk along authored `Path3D` routes in `scene/outdoor_npc_paths.tscn`, covering about 60 meters (roughly 30 meters each way). Interacting stops the NPC, switches to idle, and turns them toward the player. After Dialogic finishes, they turn back toward the sidewalk and resume from the same spot.

On these story days, the characters stay at their original locations with idle animation, including the building outcome scenes:

| Characters | Stationary days |
| :--- | :--- |
| Grandpa and Assistant | 1 |
| Mark and Cashier | 2, 4 |
| Clara and Supplier | 7, 8 |
| Jericho and Joice | 8, 9 |

Tita Elena always stays in place with her idle animation. Closed-shop NPCs still hide according to the existing building decisions. The original character model scenes and shared idle animation remain unchanged.

Edit the path curves under `NpcPatrolRoutes` in the outside-world scene to adjust their sidewalk routes. Each character's `OutdoorNpcPatrol` node exposes `walk_speed` and `turnaround_pause` for pacing.
