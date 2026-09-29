# Progress: expansion work

Branch: `claude/dreamy-edison-kyjdky`. `flutter analyze` is clean and all 210 tests pass on this commit.

## Done

### Step 1: Arabic, your name, categories, duplicates (commit 99700bc)
- The app is in English and funny Egyptian Arabic. It follows the phone's language, and you can switch it in Settings.
- The friends' join page also speaks Arabic, right to left, when their browser is in Arabic.
- Your default name is saved in Settings and filled in when you open a room.
- 14 preset categories, plus a custom category you type yourself.
- "Same name twice" is a room option. It is allowed by default, and when it's off the app blocks the same name even when it's spelled differently.

### Step 2: Team race, share card, team picking (commit 45609e2)
- Team race (Celebrity) mode, since replaced by Face-off (see below).
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

### Join a game, and the hotspot fix (branch `claude/fix-game-detection-a62gmc`)
- **Why games weren't detected:** the app never had a way to find rooms; joining was only by QR code or link.
- **Join a game** (home screen): lists rooms open on the same Wi-Fi or hotspot and opens one in the browser, the same page the QR code opens.
  - The host announces the room with a small UDP broadcast every second on port 8183 (`udp_room_beacon.dart`), to every local network, not only the default one.
  - The list shows the host, category, mode, room code, players in, or "Already playing". A room drops off 4 s after it goes quiet.
  - Android holds a multicast lock only while the list is open.
- **Hotspot bug:** after "Create hotspot", the app turned the hotspot off by itself as soon as the phone looked like it was on Wi-Fi (some phones report the app's own hotspot as Wi-Fi), briefly showed the dead address, then "Create hotspot" again with no message.
  - The hotspot now stays on until the host taps "Switch to Wi-Fi", which is offered when Wi-Fi appears.
  - The app's own hotspot address, and for 15 s after it stops, is never mistaken for Wi-Fi.
  - When Android turns the hotspot off (usually on leaving the app), the lobby says so.
  - A hotspot that stopped before it started no longer leaves "Starting hotspot" spinning forever.

### Join a game: camera scan and a funnier wait
- **Scan the host's code** at the top of "Join a game" opens the camera (`mobile_scanner`, `scan_screen.dart`) and closes on the first QR code:
  - The game link opens the room in the browser.
  - The app hotspot's Wi-Fi code shows the network name and password, with Copy and "Open Wi-Fi settings". Then you scan the game code, or pick the room from the list.
  - Any other code says it isn't a game code. A blocked camera says how to allow it.
- The **list of games on this Wi-Fi** stays under the scan button and keeps updating.
- **While it looks:** the bowl gives a shake every couple of seconds, and the line under it rotates through jokes ("Knocking on the neighbours' doors…", "بنسأل طنط مين فاتح قعدة النهارده…"). With reduced motion on, it stays still.
- Camera permission was added for Android and iOS.

### New app icon and Play Store assets (branch `claude/project-thread-pzjw84`)
- New icon: the home-screen bowl (app purple, yellow paper slips, a handwritten "?") on a light lavender background, in the app's own colours and fonts, drawn from vector art in `store/tool/make_assets.mjs` (re-run with `node store/tool/make_assets.mjs`).
- Android: legacy and round icons for every density, adaptive icon layers, and a monochrome layer for Android 13 themed icons. iOS: every AppIcon size.
- Fixed an Android build break (`mergeDebugResources`: "Invalid <color>"): the script wrote `undefined` into `ic_launcher_background.xml`. It now writes the lavender `#E3E0FF`.
- `store/`: the 512x512 Play icon, the 1024x500 feature graphic, and a 1080x1920 phone screenshot frame. Put real screenshots in `store/screenshots/raw/` and re-run the script to get framed `phone_N.png` files.

### Pass the phone (branch `claude/pass-the-phone-mode-0auij5`)
- **The idea:** one phone, no Wi-Fi. The phone goes round the table and each person types their own name and secret names in private. Nobody types a list of players. Design mockups: https://claude.ai/artifact/JSJfDcCM19HdAAzBezcV8G
- **Home:** a third tile, "Pass the phone" / "عدّي الموبايل", drawn as a paper slip. The home bowl is smaller on short screens so all three tiles fit.
- **Setup:** Classic or Team race (the family game needs everyone's phone), teams random or arranged by the host, category, names each, "Same name twice". Shared widgets moved to `room_options.dart`.
- **Your turn** (`your_turn_screen.dart`): your name (the owner's saved name for the first turn), then the secret names on paper slips. A slip hides itself when you move to the next box. After a round, earlier players tap their name to keep their colour.
  - Same checks as the join page, plus two players can't share a name ("Sara is already in. Add a letter").
- **Keeping names secret:**
  - After "Into the bowl" the names are never shown again until the reading.
  - The hand-off screen shows only who is in, and Back from a turn returns to the hand-off, never to the last person's slips.
  - Leaving the app mid-turn wipes the typed secret names.
  - Android blocks screenshots and the recent-apps preview on the typing screen (`FLAG_SECURE` via `family_game/secure_screen`). iOS has no equivalent block.
- **Not starting by mistake:** from 3 players (4 for Team race), "Hold to start the game" needs a 2-second press and hold, then "Is everyone in?" lists the players with "Yes, start the game" / "No, keep passing". Back while passing asks "Stop passing?".
- **Then:** Classic shows "Give the phone to whoever reads the names out", then the usual read-aloud and reveal. Team race goes straight to the teams. "New round" keeps everyone and empties the bowl; "End game" goes home.
- **Tests** (21 new): `test/features/pass_phone/` covers the rules, the whole flow, the hold (a tap or a short hold does nothing), slips hiding, the wipe on leaving the app, the name clash, Back, Team race, and Egyptian Arabic in portrait and landscape.
- **Fixed on the way:** the hold button never filled when the page could scroll (landscape, small phones), because the tap recogniser waited for the scroll to lose. It now listens to the raw press.

### Family online survives Wi-Fi drops (branch `claude/project-thread-jxaml7`)
- **Friend's page:** after two failed calls (about 3 s) a red "Reconnecting… Your game is safe." bar shows. Ask is disabled so a guess can't be lost or sent twice, and every call gives up after 4 s instead of hanging. When the phone is back it turns green ("You're back in the game!") with no reload. After about 15 s it adds: check the Wi-Fi, and scan the new code if the host changed Wi-Fi. Coming back from the lock screen catches up at once.
- **Chat typed while offline** waits as "sending…" and goes out in order once the phone is back.
- **Who's offline:** the host's server marks a friend offline after 6 s without a call (`LanRoomHost.checkPresence`), and back on their next call. Friends' pages show "· offline", the host's chips a Wi-Fi-off icon.
- **The turn can't get stuck:** if a family's head is offline, any member still here asks for the family (the family stays the head's). If the whole family is offline, everyone sees "Nour's family is offline" and the host gets "Skip their turn". The app never skips anyone by itself.
- **Back on a new phone or browser** (or after the host's address changed, which loses the cookie): the page shows "Were you playing? Tap your name" with only the offline players. The host gets "Someone wants back in as Nour" with Let them in / Not them. Once let in, that browser gets Nour's id and simply is Nour.
- **Host:** a QR button on the family screen shows the room's current join codes (the same card as the lobby, hotspot included), so people can scan back in mid-game.
- **Fixed:** on Arabic phones the "who caught whom" line came out scrambled when names were in English (inserted names are now isolated).
- **Tests:** rules (stand-in asker, skip, claims), the view, the server (presence with a fake clock, a seat handed over with its cookie), and the host screen (let in, not them, skip, asking for an offline head, join code). Checked in headless Chromium: a phone going offline and back with a queued message, and an Arabic phone coming back in a new browser and getting its seat after approval.

### Face-off replaces Team race (2026-09-28)
- **Why:** Mafdy found Team race was just عروستي (charades with the bowl's names) and wanted a team mode rooted in "guess who wrote it". Picked "Face-off + bets" from two ideas (the other was Partners).
- **Rules** (`lib/features/celebrity/domain/face_off_game.dart`): teams take turns; the app draws the next name that nobody on the team on turn wrote; the team picks which player on another team wrote it. Right +1; a double bet is +2 right, −1 wrong. Duplicate names: either writer counts. A team with nothing left to guess is skipped; the game ends when the bowl is empty. No timer.
- **Screens:** Teams (with How to play), Pick (name on a slip, the other teams' players as chips, "Bet double" switch, "{name} wrote it!"), Reveal (right/wrong, who wrote it, points, scoreboard), Results.
- **Removed:** the turn clock, hand-off, Got it/Skip, turn length setting, 3–5 names each and the 12-name minimum. Names each is 1–3 like Classic; every team still needs 2 players.
- Guests' pages say "The face-off is on!" and to keep a straight face. Internals keep the `celebrity` names (`GameMode.celebrity`, `CelebrityCubit`).
- **Tests:** `test/features/celebrity/face_off_game_test.dart` (turns, scoring, bets, duplicates, skipped team, 3 teams, cubit) and the full flow in `screens_test.dart`.

### The agreed ideas, built (2026-09-29, branch `claude/project-thread-phy2qn`)
- Source of truth for the list: `/mnt/project-files/design/game-ideas-recap.md`. Hurry up (15 s clock) was not answered, so not built.
- **Face-off fixes:** 3 names each by default (up to 5, `Room.namesForMode`); the reveal shows only right/wrong after a drumroll; the results list who wrote what.
- **Family online house rules** (`FamilyTwists`, room switches, all off by default), in `family_game.dart` with tests in `test/features/family/family_twists_test.dart`: secret catches, counter-catch, wanted, revenge, rumors, فكّك مني. The host app and friends' browser pages both answer the prompts (`/game/letmego`, `/game/counter`, `/game/passcounter`, `/game/revenge`, `/game/passrevenge`, `/game/rumor`).
- **Handwritten slips:** a room option in Classic, Face-off, Family online and Pass the phone. Drawings are PNGs (`SlipInk`), sent from browser canvases, served at `/ink/<id>.png`.
- **Sound effects:** `GameSounds` (drumroll, zaghrouta, sad trombone; generated by `tool/make_sounds.py`), a settings switch, and `/sounds/*.wav` for browsers with a mute button. With secret catches, sounds only play for results the phone may see.
- **Awards of the night + family tree** (`night_awards.dart`): at the end of Family online, on the host screen, the share picture and friends' pages.
- **Not checked on a phone yet:** everything above, especially sounds, drawing with a finger and the twist prompts in a phone browser.

### Rules and Wi-Fi check of every mode (branch `claude/project-thread-jxaml7`)
- **Team race** (since replaced by Face-off, above):
  - Starts at 3 names each (up to 5) and needs 12 names in the bowl.
  - One round only (Mafdy's pick after play-testing 2026-09-28: repeating the same names over 3 rounds felt wrong). Each name is guessed once; the bowl emptying ends the game. Every turn gets the full clock.
  - The name on screen at time-up is shuffled back in, not handed to the next team.
  - Every team needs 2 players; the host can move people even when friends picked teams.
  - The clock pauses (and hides the name) when the app is hidden, on Back, or with Pause.
  - A "How to play" card before round 1.
  - Guests' pages say "The team race is on!" instead of the reading text.
- **Classic and Pass the phone:**
  - A host part-way through their names isn't counted in yet.
  - Two players can't share a name.
  - Emoji-only names no longer clash.
- **Join page (all modes, before the game):**
  - Reconnecting / still offline / connected again bar, and polls with a timeout.
  - Typed names are kept in the browser, and sending while offline is held back.
  - The id cookie lasts 12 hours, and a first post without a cookie still gets in.
  - A page left open from an earlier room reloads instead of joining the new one.
  - The host can tap a friend in the lobby to take an old entry out, e.g. after they rejoined on a new phone.
- **Family online:**
  - Phones see players only by a public id, so nobody can copy a cookie and play as someone else.
  - Presence resets for a new game and after the host's phone slept.
  - Seat claims:
    - only while the player is really away;
    - one open claim per browser;
    - a refused browser can't ask again.
  - Chat:
    - failed messages retry;
    - a resend is never posted twice;
    - polls run one at a time.
  - After a win, a lost connection says the game is over instead of "Reconnecting".
  - Duplicate names match the room's Arabic-aware rule, and caught people can't be asked about.
  - Your own names aren't offered in "Which name?".
- **Checked in headless Chromium:**
  - The Classic page going offline, keeping what was typed, coming back and joining.
  - A second "Omar" being refused, then let in after the host took the old entry out.
  - A three-phone Family game with no page errors.
- **Keeping the room alive (Android):**
  - While a room is open, a "Hosting a game" foreground service (`HostingService.kt`, `KeepHosting` widget) keeps the app, the CPU and Wi-Fi awake, so a call, the lock screen or another app doesn't end the game.
  - Android 13+ asks once for notification permission; hosting works without it.
  - The debug APK now builds in the cloud session. All the Kotlin compiles, including the earlier hotspot, multicast and screenshot-block code, but nothing has run on a phone yet.
- **The host stepping away:** when the host leaves the app during Family online, they show as offline. A family member then asks for them, as for any friend. Nobody can claim the host's seat.
- **Not done:** leaving a reading reopens the bowl.

## Remaining
1. **On a real device:** play the browser family page on 3+ phones over Wi-Fi and on the app's hotspot (polling, chat, voting, the vibration on your turn). Turn one phone's Wi-Fi off and on mid-game, and open the game in a second browser to take a seat back.
2. **On a real device:** "Join a game" on a second phone, on home Wi-Fi and on the app's hotspot, including scanning both codes; and "Create hotspot" staying on. The Kotlin changes (multicast lock, hotspot stop, Wi-Fi settings) were not compiled in the cloud session.
3. **On a real device:** a Pass the phone round with 3+ people; check that Android blocks a screenshot on the typing screen (the Kotlin change was not compiled in the cloud).
4. **Store listing:** take 2 to 8 real phone screenshots and frame them (see `store/README.md`). Check the new icon on a real launcher.

## Deferred by you
- Free vs paid: Mafdy wants to decide this now that the ideas are built.
- Paid app vs in-app purchase: one-time purchase agreed (no ads, no subscription); price, what's paid and any player limit still open. No code yet.
- Face-off (replaces Team race, 2026-09-28): Mafdy to play-test it on the Pixel.

## Bugs you mentioned
- **Fixed:** closing the custom category dialog without a name threw an error (its text box was thrown away while the dialog was still fading out).
- **Fixed:** screens that showed an error or drew nothing when moving between them:
  - Leaving the room while a message (like "Link copied") was up during the new room/lobby switch.
  - Flipping quickly between the hotspot's "Join the Wi-Fi" and "Open the game" steps, or the lobby's network card changing and changing back.
  - Found by a random-tapping test (80 sessions of 400 taps, with and without animations); `test/navigation_test.dart` and `test/core/motion/stage_motion_test.dart` cover each one.
- **Fixed:** "Create hotspot" failing silently (see Join a game, and the hotspot fix, above).
