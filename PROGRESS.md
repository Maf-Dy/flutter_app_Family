# Progress: expansion work

Branch: `claude/dreamy-edison-kyjdky`. `flutter analyze` is clean and all 88 tests pass on this commit.

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

### Step 3: Family online mode (about 50% done, not visible in the app yet)
Done and tested:
- `lib/features/family/domain/family_game.dart` holds all the rules:
  - Each player starts as their own family.
  - Only the head of a family asks "did X write Y?".
  - A right guess brings the caught person's whole family into yours, and you guess again.
  - A wrong guess passes the turn to the family of the person you asked.
  - The last family standing wins.
  - Family members can suggest guesses and back them with votes.
  - There's a private chat per family.
  - Duplicate names are handled fairly: asking about either copy of a repeated name counts.
- The room can start a family game (`Room.startFamily`), and the "Family chat" on/off room option exists in state (`RoomCubit.setFamilyChat`).
- On the server, `lan_room_host.dart` has:
  - `GET /game`: each phone sees only its own family's ideas and chat, and who wrote a name only once it's revealed.
  - `POST /game/guess|suggest|unvote|say`.
- The friends' in-browser family page (`family_page.dart`, `JoinPage.family`) is written, with English and Egyptian Arabic words.
- On the host side, `FamilyTable`, `HostFamilyTable`, `FamilyArgs`, `FamilyCubit` and `RoomCubit.startFamily()` are in place.

## Remaining (step 3)
1. **Host's family screen** (`lib/features/family/presentation/screens/family_screen.dart`) with:
   - A turn banner.
   - The host's family.
   - Who/which pickers and an Ask or Suggest button.
   - The ideas list with votes, and the chat.
   - The board of families, names and last guesses.
   - The winner view with a share card, New round and End game (`GameExit`).
   - A spectator view when the host wrote no names.
2. **A `/family` route** in `app_router.dart`, and a lobby `_startReading` branch that calls `cubit.startFamily()` and pushes it. It currently returns early for family mode.
3. **New room screen**: a third mode option ("Family online" / "العيلة أونلاين") and a "Family chat" switch that shows only for that mode.
4. **App strings** (app_en.arb / app_ar.arb) for the family screen and mode, then `flutter gen-l10n`.
5. **Tests**:
   - Privacy of `familyViewFor`.
   - The `/game` endpoints in `lan_room_host_test`.
   - The family screen at phone portrait and landscape, LTR and RTL.
   - The join page's family HTML in Arabic.
6. **On a real device**: try the browser family page on 3+ phones (polling, chat, voting), then update the README.

## Deferred by you
- Paid app vs in-app purchase: decide later. No code yet.

## Bugs you mentioned
Please list the bugs you saw (screen, what you did, what happened), so they can be fixed first next session.
