# Family Game

A party game for the living room. Everyone secretly drops a name in the bowl, the host reads them out, and then the phone goes down on the table while you play: ask "Did you write …?", and whoever you catch joins your family. The last family standing wins.

The host's phone runs the room. Friends join from their phone's browser by scanning a QR code, so they don't need the app, and no internet is needed.

| Home | New room | Lobby | Read aloud |
|---|---|---|---|
| ![Home](docs/screenshots/home.png) | ![New room](docs/screenshots/new_room.png) | ![Lobby](docs/screenshots/lobby.png) | ![Read aloud](docs/screenshots/read_aloud.png) |

| Names on the table | Who wrote what? | No Wi-Fi: app hotspot | Friend's phone |
|---|---|---|---|
| ![Board](docs/screenshots/board.png) | ![Who wrote what](docs/screenshots/who_wrote.png) | ![Hotspot](docs/screenshots/lobby_hotspot_dark.png) | ![Join page](docs/screenshots/guest_join.png) |

## How a game goes

1. **Host a room.** Pick a category and how many names each player writes.
2. **Friends join.** They scan the QR code and type their name and their secret name(s). The host sees who has joined, never what they wrote.
   - **On Wi-Fi:** one QR code with the game link.
   - **No Wi-Fi (Android 8+):** tap **Create hotspot**. Code 1 joins the hotspot with the camera, code 2 opens the game.
   - **iPhone host, no Wi-Fi:** turn on Personal Hotspot in Settings and come back. The app picks it up.
3. **Read aloud.** One slip at a time, in random order. Read them once or twice.
4. **Names on the table.** The list stays on screen (the screen stays awake) in case anyone forgets a name. Play at the table.
5. **Who wrote what?** Optional, after the game: each slip flips to show who wrote it. Then start a new round in the same room.

## Running it

Requires Flutter 3.44 (Dart 3.12).

```sh
flutter pub get
flutter run
```

Checks:

```sh
flutter analyze
flutter test
```

The tests cover the game rules, the HTTP host (including HTML escaping and the closed-bowl rules), both state holders, and every screen at 360×800 and 800×360 in left-to-right and right-to-left.

### Release signing

`android/app/build.gradle.kts` signs release builds with `android/key.properties` when that file exists (it is git-ignored), as in the [Flutter deployment guide](https://docs.flutter.dev/deployment/android#configure-signing-in-gradle):

```properties
storePassword=…
keyPassword=…
keyAlias=…
storeFile=/path/to/upload-keystore.jks
```

Without it, release builds fall back to the debug key.

## How it's built

Feature-first layout with cubits (`flutter_bloc`) for state:

```
lib/
├── main.dart, app.dart            # wiring: real network + HTTP host, theme, routes
├── core/
│   ├── theme/                     # light and dark ColorSchemes, GameColors extension
│   ├── motion/                    # durations, curves, shared-axis transitions
│   ├── platform/haptics.dart
│   ├── router/app_router.dart
│   └── widgets/                   # KeepScreenOn, PlayerAvatar
└── features/
    ├── room/                      # hosting: new room + lobby
    │   ├── domain/                # Room rules, RoomHost and NetworkAccess contracts
    │   ├── data/                  # LanRoomHost (HTTP server), JoinPage (HTML), DeviceNetwork
    │   └── presentation/          # RoomCubit, home / new room / lobby screens
    └── round/                     # read aloud, names on the table, who wrote what
        ├── round_route.dart       # RoundArgs / RoundExit: what the lobby hands over
        └── presentation/          # RoundCubit and screens
android/app/src/main/kotlin/…/LocalHotspot.kt   # Android local-only hotspot bridge
```

- **Room hosting.** The server listens on every IPv4 interface on port 8182, falling back to any free port. It keeps working when the phone moves between Wi-Fi, its own hotspot and the app's hotspot; only the address shown in the QR code changes. Each friend gets a random id cookie, so they can edit their slip until reading starts.
- **Hotspot.** Android's `LocalOnlyHotspot`. It needs the Nearby devices permission on Android 13+, and Location on Android 8–12 (location itself is never read).
- **Motion.** Material 3 easing: shared-axis page and stage transitions, slips that flip and settle, a slip that drops into the bowl when a friend joins. All of it turns off when the system "remove animations" setting is on. Haptics mark a name arriving, reading starting, and each slip turning.
- **Fonts** (bundled, so they work offline): Bricolage Grotesque, Nunito and Kalam, under the SIL Open Font License (`assets/fonts/OFL-*.txt`, also listed on the app's licences page).
