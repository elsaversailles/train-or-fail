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
* Submitting scores outside a ±0.20 margin of error records a mistake. Accumulating 3 mistakes in a single shift results in immediate contract termination and game over.

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

The story concludes with one of six narrative endings determined by your cumulative score and decisions regarding special applicants:

| Ending Title | Condition & Route | Narrative Outcome |
| :--- | :--- | :--- |
| **Algorithm Reformer** | All 4 special story NPCs are approved as "legit". | The player systematically overrides algorithmic bias, sparking institutional reform. |
| **Stagnant Survival** | Total score across the game is exactly 27 / 45; player selects Option 1. | The player stays at their desk, surviving corporate downsizing into endless monotony. |
| **The Clean Exit** | Total score across the game is exactly 27 / 45; player selects Option 2. | The player hands in their resignation and walks away clean. |
| **Cold Efficiency** | All 4 special NPCs are marked "sus", and Grandpa is rejected as "sus" during the Day 10 bonus shift. | Absolute compliance. Personal ties are eliminated in favor of complete corporate assimilation. |
| **Conflict of Interest** | All 4 special NPCs are marked "sus", but Grandpa is approved as "legit" during the Day 10 bonus shift. | The cold facade fractures at the final hurdle, exposing personal bias to internal audit. |
| **Another Cog In The Machine** | Mixed verdicts on special applicants (neither all "sus" nor all "legit"), and total score != 27. | A standard evaluation cycle. The player remains an unremarkable, replaceable bureaucrat. |

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