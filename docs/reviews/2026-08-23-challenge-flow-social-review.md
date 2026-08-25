# The challenge flow after pairing — what it does, and what it should do

> 2026-08-23 · audit of the loop shipped in #132/#133, read against the goal:
> **this gamification exists to make people socialise.**
> Every claim below is checked against the code, not remembered.

---

## 1. What happens today

Two people scan each other and the challenge list opens. From there:

```
A scans B's profile QR
  → sheet: "Paired with B" + this event's challenges
A taps a challenge
  → POST /challenges/initiate  (challenger = A, verifier = B)
  → A's screen shows a VERIFY QR
B scans A's screen
  → sheet: "Did A complete X?" → CONFIRM
  → POST /challenge-completions/{id}/verify
A's screen polls → "+15 XP"
```

Verified in the backend:

| Fact | Where |
|---|---|
| **Only the challenger is paid.** `verify()` increments `total_points` and `total_challenges_completed` on the *challenger's* profile. The verifier gets nothing. | `ChallengeCompletionService::verify` |
| Both must be checked in to the event | same, `initiate` |
| A pair cannot repeat the same challenge | same — uniqueness on (challenge, event, challenger) |
| Max 10 challenges per attendee per event (`max_challenges_per_attendee`) | `ChallengeCompletionService:86` |
| An event leaderboard endpoint exists — **and the app never calls it** | `GET /events/{event}/leaderboard`; `eventLeaderboardProvider` has no consumer |
| A friendship graph exists — **and this flow never touches it** | `FriendshipService` |

## 2. The five problems

### 2.1 It pays one person and taxes the other

This is the structural one. A earns 15 XP; B does the confirming and earns **nothing**. So:

- B has no reason to take part beyond politeness;
- the second time you ask someone to verify you, you are asking a **favour**;
- the natural equilibrium is people avoiding being the verifier.

A social mechanic where one side is unpaid labour does not compound. It is the opposite of what we want: we want the *interaction* to be worth having for both.

### 2.2 The app is a ledger, not a game

The challenge itself happens in the room. The app records that it happened. Nothing in the app *is* the game — no shared screen, no simultaneity, no timer, no reveal. Which means the phone is paperwork, and paperwork between two strangers is the opposite of an icebreaker.

### 2.3 Three scans of phone-fiddling for one human moment

A scans B. A shows a QR. B scans A. For a single interaction, the phones are **between** the two people for most of it, when they should be out of the way within seconds.

### 2.4 Nothing remembers that they met

A completed challenge leaves two ledger rows and no relationship. No "you met Ana at Sunset Run", no connection, no reason for the second meeting to be worth more than the first. `FriendshipService` exists and this flow ignores it.

### 2.5 There is no room

Everything is 1:1. Nothing tells you that 27 people are checked in, who is on the board tonight, or that the room has a shared goal. Strangers stay strangers-in-pairs instead of becoming a group — and the event leaderboard the backend already serves is not on screen anywhere.

Compounding all of it: earned XP has **nowhere to land**. Badges, wallet, stats and leaderboard are still unreachable (BACKLOG NF-21), so the reward disappears.

## 3. How others solve exactly this

Patterns, not citations — described at the level we can learn from.

**The pair is the unit — Duolingo Friend Quests.** Two people share one goal and *both* earn from it. It is the direct answer to §2.1: nobody is the unpaid verifier because there is no verifier, only two participants in the same quest.

**Co-presence pays both sides — Pokémon GO.** Gifts, raids and trades all require being near someone, and both parties get something. Crucially the **relationship levels up**: Good → Great → Ultra → Best Friend, with repeat interaction unlocking real value. That is §2.4 solved as a mechanic rather than a record.

**Make the gesture free — Strava kudos.** One tap, costs nothing, reciprocal, and it is the backbone of that product's social layer. Contrast with our three-scan ceremony: friction is the enemy of a social gesture.

**Simultaneity is the game — BeReal.** Both phones do the same thing at the same moment. It is the cheapest possible way to make an app feel like a shared event rather than two forms.

**Repeat presence becomes status — Foursquare mayorships.** Turning up again and again earns something visible to others. Answers "why come back".

**The pair itself accrues value — Snapchat/Zenly streaks.** The relationship has a number on it, and neither person wants to break it.

**The room is a team — pub quizzes, escape rooms.** Rounds, a host, a live scoreboard, a reveal. Strangers become a team because they share a goal and a clock — §2.5 in its most proven form.

**Structured icebreakers — Timeleft, Lunchclub, Bumble BFF.** The product supplies the prompt so neither stranger has to invent one. Our challenges are already this; we just do not use them socially.

## 4. What the flow should be

Ordered by leverage, not by effort.

### 4.1 Pay both sides (backend, small, highest leverage)

A completed challenge credits **both** profiles. One line of intent in `ChallengeCompletionService::verify`, and the whole social logic changes: confirming stops being a favour and becomes participation. Points can differ (challenger full, partner a share) but the partner must not be zero.

### 4.2 One scan, one confirm

Drop the second QR. A scans B → both phones show *the same thing*: "You two: Take a selfie together — 15 XP each" with a single **Confirm** on B's side. Same endpoints, one less scan, and the phone leaves the conversation faster.

### 4.3 Let the app hold the moment

Once agreed, a shared screen: the challenge, a countdown, then a simultaneous reveal of "+15 XP each" on both devices. This is what turns paperwork into a game, and it is mostly presentation over the calls we already make.

### 4.4 Remember the meeting

On a completed challenge, create a connection (`FriendshipService`) and show "you met 4 new people tonight". Then make the *second* meeting worth more — a pair streak, or a "played together 3 times" badge. That is the Pokémon GO friendship ladder, and it is why people come back.

### 4.5 Put the room on screen

The event leaderboard is already served and unused. Show it live during the event, plus "27 checked in", plus one **collective goal** ("the room needs 20 challenges tonight"). A shared target is the cheapest way to make strangers a team.

### 4.6 Give XP somewhere to land

NF-21. Without it every improvement above still ends in a number that vanishes.

## 5. What I would not do

- **Leaderboards as the primary frame.** Ranking strangers competitively at a social event pushes the confident up and everyone else out. Collective goals first, ranking as a side dish.
- **Streaks that punish.** A streak you can lose creates obligation, not warmth — fine for a language app, wrong for turning up to a run club.
- **More challenge types before fixing §4.1.** Content does not fix an incentive that pays one side.

## 6. Open questions for product

1. **Split or double?** Does the partner get the same points, or a share? Same is simpler to explain and to draw; a share protects the economy.
2. **Is the "verifier" role worth keeping at all?** §4.2 removes it as a *role* but keeps a confirmation. Do we need dishonesty protection beyond "the other person has to tap yes"?
3. **How much of the challenge should the app run?** A timer and a reveal is cheap. Anything more (photo upload, quiz, location proof) is a much bigger build and should be justified by a real behaviour we want.
4. **Does a pair streak fit the brand?** It is the strongest return mechanic on the list and also the most obligating.
