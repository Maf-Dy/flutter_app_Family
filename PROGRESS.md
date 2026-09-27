# Progress: expansion work

Branch: `claude/dreamy-edison-kyjdky`. `flutter analyze` is clean and all 107 tests pass on this commit.

## Done

### Step 1: Arabic, your name, categories, duplicates (commit 99700bc)
- The app is in English and funny Egyptian Arabic. It follows the phone's language, and you can switch it in Settings.
- The friends' join page also speaks Arabic, right to left, when their browser is in Arabic.
- Your default name is saved in Settings and filled in when you open a room.
- 14 preset categories, plus a custom category you type yourself.
- "Same name twice" is a room option. It is allowed by default, and when it's off the app blocks the same name even when it's spelled differently.

### Step 2: Team race, share card, team picking (commit 45609e2)
- Team race (Celebrity) mode: 2–4 teams, a 30/45/60/90 s timer, and three rounds (describe, one word, act it out).
- Teams can be random, picked by players on the join page, or arranged by the host.
- A shareable end-of-night picture card for team race results and for the classic who-wrote-what reveal.

### Step 3: Family online mode (done, in the app)
- **Rules** (`lib/features/family/domain/family_game.dart`):
  - Each player starts as their own family, and only the head of a family asks "did X write Y?".
  - A right guess brings the caught person's whole family into yours, and you guess again.
  - A wrong guess passes the turn to the family of the person you asked. The last family standing wins.
  - Family members suggest guesses and back them with votes, and each family has a private chat.
  - Duplicate names are handled fairly: asking about either copy of a repeated name counts.
  - Caught people are no longer offered as someone to ask, since their names are already out.
- **New room:** a third mode, "Family online" / "العيلة أونلاين", with a "Family chat" switch that shows only for that mode.
- **Lobby:** "Let's play" deals the bowl into the game and opens the host's family screen.
- **Host's family screen** (`family_screen.dart`):
  - A turn banner and the host's family.
  - Who/which pickers with Ask (head, on the family's turn) or Suggest.
  - Family ideas with votes and Use, and the family chat.
  - The board: families, names (with who wrote the ones that are out) and the last guesses.
  - The winner view with confetti, a share card, New round and End game.
  - A watcher view when the host put no name in. Back asks first, then returns everyone to the lobby with the names kept.
- **Friends' browser page:** polls `/game` every 1.5 s. Each phone sees only its own family's ideas and chat.
- **Fixed on the browser page:**
  - The pickers and Suggest button stayed visible after a win and for watchers: a card's own style overrode `hidden`.
  - Caught people were offered in "Who wrote it?".
- **Tests** (107 in total):
  - Privacy of `familyViewFor`.
  - The `/game` endpoints, and the Arabic family page.
  - The family screen at phone portrait and landscape, LTR and RTL, and in Egyptian Arabic.
  - The watcher and member flows.
- **Browser check:** three headless Chromium phones played a whole game against the real server, with no page errors. Covered: a wrong guess, a catch, chat following the family, a suggestion used by the head, the win, and a late arrival who only watches.

## Remaining
1. **On a real device:** play the browser family page on 3+ phones over Wi-Fi and on the app's hotspot (polling, chat, voting, the vibration on your turn).

## Deferred by you
- Paid app vs in-app purchase: decide later. No code yet.

## Bugs you mentioned
Please list the bugs you saw (screen, what you did, what happened), so they can be fixed first next session.
