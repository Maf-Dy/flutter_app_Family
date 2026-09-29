// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Family Game';

  @override
  String get wordmark => 'family';

  @override
  String get you => 'You';

  @override
  String youSuffix(String name) {
    return '$name (you)';
  }

  @override
  String get homeHeadline => 'Who wrote\nwhat?';

  @override
  String get homeTagline =>
      'Everyone secretly drops a name in the bowl. Then put the phone down and play.';

  @override
  String get hostRoom => 'Host a room';

  @override
  String get hostRoomDetail =>
      'Friends join from their phone\'s browser. No app, no internet needed.';

  @override
  String get howToPlay => 'How to play';

  @override
  String get howToPlayStep1 =>
      'Everyone scans the QR code and secretly writes a name from the category.';

  @override
  String get howToPlayStep2 =>
      'The host reads all the names aloud, once or twice.';

  @override
  String get howToPlayStep3 =>
      'Put the phone down. Take turns asking someone \"Did you write …?\" Guess right and they join your family. The last family standing wins.';

  @override
  String get howToPlayStep4 =>
      'Afterwards, tap \"Who wrote what?\" to see them all.';

  @override
  String get gotIt => 'Got it';

  @override
  String get settings => 'Settings';

  @override
  String get yourName => 'Your name';

  @override
  String get yourNameHint => 'What friends call you';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Phone\'s language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربي المصري';

  @override
  String get done => 'Done';

  @override
  String get newRoom => 'New room';

  @override
  String get category => 'Category';

  @override
  String get categoryFamousPeople => 'Famous people';

  @override
  String get categoryActors => 'Actors';

  @override
  String get categorySingers => 'Singers';

  @override
  String get categoryFootballers => 'Footballers';

  @override
  String get categoryMovies => 'Movies';

  @override
  String get categorySeries => 'TV series';

  @override
  String get categoryCartoons => 'Cartoon characters';

  @override
  String get categoryAnimals => 'Animals';

  @override
  String get categoryCountries => 'Countries';

  @override
  String get categoryCities => 'Cities';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryBrands => 'Brands';

  @override
  String get categoryPeopleWeKnow => 'People we all know';

  @override
  String get categoryAnything => 'Anything goes';

  @override
  String get categoryCustom => 'Your own…';

  @override
  String get customCategoryTitle => 'Your own category';

  @override
  String get customCategoryHint => 'e.g. Teachers from school';

  @override
  String get cancel => 'Cancel';

  @override
  String get use => 'Use';

  @override
  String get namesPerPlayer => 'Names per player';

  @override
  String get namesPerPlayerDetail => 'More names, longer game';

  @override
  String get fewerNames => 'Fewer names';

  @override
  String get moreNames => 'More names';

  @override
  String namesPerPlayerValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count names per player',
      one: '1 name per player',
    );
    return '$_temp0';
  }

  @override
  String get rules => 'Rules';

  @override
  String get sameNameTwice => 'Same name twice';

  @override
  String get sameNameTwiceOn =>
      'Allowed. Two people writing the same person makes for a funny round.';

  @override
  String get sameNameTwiceOff =>
      'Not allowed. Whoever writes it second is asked to pick someone else.';

  @override
  String get connection => 'Connection';

  @override
  String get checkingWifi => 'Checking Wi-Fi…';

  @override
  String get oneMoment => 'One moment.';

  @override
  String get connected => 'Connected';

  @override
  String get connectedDetail =>
      'Friends join the same Wi-Fi, or your hotspot, and scan the code.';

  @override
  String get hotspotIsOn => 'Hotspot is on';

  @override
  String get hotspotIsOnDetail =>
      'Friends scan the Wi-Fi code first, then the game code.';

  @override
  String get startingHotspot => 'Starting hotspot…';

  @override
  String get noWifiHere => 'No Wi-Fi here';

  @override
  String get noWifiCanCreate =>
      'No problem. The app can make its own hotspot for the room.';

  @override
  String get noWifiCannotCreate =>
      'Turn on Wi-Fi or your phone\'s hotspot. You can do it after opening the room.';

  @override
  String get connectionNote =>
      'Checked automatically. Nothing goes over the internet; the room lives on this phone.';

  @override
  String get openRoom => 'Open room';

  @override
  String get openRoomFailed =>
      'Couldn\'t open the room. Close other apps that share on Wi-Fi and try again.';

  @override
  String get closeRoom => 'Close room';

  @override
  String get closeRoomTitle => 'Close the room?';

  @override
  String get closeRoomBody =>
      'Friends\' pages stop working and the names in the bowl are cleared.';

  @override
  String get keepOpen => 'Keep open';

  @override
  String get roomOpen => 'Room open';

  @override
  String get hotspotOn => 'Hotspot on';

  @override
  String get waitingForNetwork => 'Waiting for a network';

  @override
  String playersInChip(String label, int count) {
    return '$label · $count in';
  }

  @override
  String get linkBroken =>
      'This phone couldn\'t open its own link, so friends won\'t either. Tap Check again, or use a hotspot.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get linkNotOpening => 'Link not opening?';

  @override
  String get onWifiNow =>
      'You\'re on Wi-Fi now. Friends on the hotspot stay connected until you switch.';

  @override
  String get switchToWifi => 'Switch to Wi-Fi';

  @override
  String inTheBowl(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in the bowl',
      one: '1 in the bowl',
      zero: 'Bowl\'s empty',
    );
    return '$_temp0';
  }

  @override
  String get readyWhenYouAre => 'Ready when you are';

  @override
  String morePlayersToStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more players to start',
      one: '1 more player to start',
    );
    return '$_temp0';
  }

  @override
  String get startReading => 'Start reading';

  @override
  String get yourSecretName => 'Your secret name';

  @override
  String yourSecretNameOf(int index, int total) {
    return 'Your secret name ($index of $total)';
  }

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get dropInBowl => 'Drop in the bowl';

  @override
  String get duplicateHostSecret =>
      'Someone already put that name in. Pick someone else!';

  @override
  String get nameIn => 'Name in';

  @override
  String get waiting => 'Waiting';

  @override
  String secretsOf(int done, int total) {
    return '$done of $total';
  }

  @override
  String arrival(String name) {
    return '$name\'s name is in';
  }

  @override
  String get scanToJoin => 'Scan to join';

  @override
  String get thenScanThis => 'Then scan this';

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String shareText(String url) {
    return 'Join our Family game: $url';
  }

  @override
  String get linkCopied => 'Link copied';

  @override
  String roomCodeLabel(String code) {
    return 'Room $code';
  }

  @override
  String qrForLink(String url) {
    return 'QR code for $url';
  }

  @override
  String qrForWifi(String ssid) {
    return 'QR code to join the Wi-Fi $ssid';
  }

  @override
  String get stepJoinWifi => 'Join the Wi-Fi';

  @override
  String get stepOpenGame => 'Open the game';

  @override
  String stepLabel(int step, String label) {
    return 'Step $step, $label';
  }

  @override
  String get scanWithCamera => 'Scan with camera';

  @override
  String get wifi => 'Wi-Fi';

  @override
  String get password => 'Password';

  @override
  String get next => 'Next';

  @override
  String privateHotspotNote(String ssid) {
    return 'This is a private hotspot made by the app, so it doesn\'t show in your phone\'s Hotspot settings. Friends see \"$ssid\" in their Wi-Fi list.';
  }

  @override
  String get noWifiAround => 'No Wi-Fi around';

  @override
  String get noWifiAroundCanCreate =>
      'The app can make a private hotspot. Friends join it by scanning a code. They lose mobile data while connected, which the game doesn\'t need.';

  @override
  String get noWifiAroundCannotCreate =>
      'Turn on your phone\'s hotspot in Settings, then come back here. Friends join the hotspot and scan the code.';

  @override
  String get createHotspot => 'Create hotspot';

  @override
  String get openSettings => 'Open settings';

  @override
  String get hotspotPermissionDenied =>
      'Android needs your permission to create the hotspot. On some phones it is called Location; the app never reads where you are.';

  @override
  String get hotspotPermissionBlocked =>
      'The permission is turned off for Family Game. Allow it in Settings, then try again.';

  @override
  String get hotspotIncompatible =>
      'Your phone\'s own hotspot is on, or this phone can\'t run a second hotspot while on Wi-Fi. Friends can join your hotspot or Wi-Fi instead: tap Check again.';

  @override
  String get hotspotNotAllowed =>
      'This phone doesn\'t let apps create a hotspot. Turn on your hotspot in Settings instead.';

  @override
  String get hotspotUnsupported =>
      'This phone can\'t create a hotspot from an app. Turn on your hotspot in Settings instead.';

  @override
  String get hotspotNoAddress =>
      'The hotspot started, but the room couldn\'t find it. Tap Check again.';

  @override
  String get hotspotFailed =>
      'Android couldn\'t start the hotspot. Make sure Wi-Fi and Location are on, then try again.';

  @override
  String get linkHelpSameWifi =>
      'Friends must be on the same Wi-Fi as this phone, with mobile data not taking over.';

  @override
  String linkHelpTypeExactly(String url) {
    return 'Type the link exactly, including the number after the colon: $url';
  }

  @override
  String get linkHelpIsolation =>
      'Office, hotel, café and guest Wi-Fi often stop phones from seeing each other. The link then never opens, whatever you try. Use this phone\'s hotspot instead.';

  @override
  String get useHotspotInstead => 'Use a hotspot instead';

  @override
  String get leaveRoundTitle => 'Leave this round?';

  @override
  String get leaveRoundBody =>
      'The names stay in the bowl, and friends can change them again.';

  @override
  String get stay => 'Stay';

  @override
  String get leave => 'Leave';

  @override
  String get readAloud => 'Read aloud';

  @override
  String get readAgain => 'Read again';

  @override
  String get readItOut => 'Read it out, then tap Next.';

  @override
  String get lastOne => 'That was the last one.';

  @override
  String get back => 'Back';

  @override
  String get nextName => 'Next name';

  @override
  String get doneReading => 'Done reading';

  @override
  String nameXofY(int index, int total) {
    return 'Name $index of $total';
  }

  @override
  String shuffling(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shuffling $count names…',
      one: 'Shuffling 1 name…',
    );
    return '$_temp0';
  }

  @override
  String get tapToSkip => 'Tap to skip';

  @override
  String get namesOnTheTable => 'Names on the table';

  @override
  String get boardHint =>
      'Put the phone down and play. The screen stays on in case anyone forgets a name.';

  @override
  String get whoWroteWhat => 'Who wrote what?';

  @override
  String get whoWroteHint => 'Tap a name, or reveal them all.';

  @override
  String get thatsAll => 'That\'s all of them!';

  @override
  String get revealAll => 'Reveal all';

  @override
  String get newRoundSameRoom => 'New round, same room';

  @override
  String get endGame => 'End game';

  @override
  String writtenBy(String slip, String name) {
    return '$slip, written by $name';
  }

  @override
  String tapToReveal(String slip) {
    return '$slip. Tap to reveal who wrote it';
  }

  @override
  String get gameMode => 'Game';

  @override
  String get modeClassic => 'Classic';

  @override
  String get modeClassicDetail =>
      'Read the names aloud, then play at the table.';

  @override
  String get modeCelebrity => 'Face-off';

  @override
  String get modeCelebrityDetail =>
      'Teams take turns guessing who on the other team wrote each name. Sure? Bet double.';

  @override
  String get teams => 'Teams';

  @override
  String get teamCount => 'Number of teams';

  @override
  String get teamPickLabel => 'Making teams';

  @override
  String get teamPickRandom => 'App shuffles';

  @override
  String get teamPickPlayers => 'Players choose';

  @override
  String get teamPickHost => 'I arrange';

  @override
  String get teamName0 => 'Purple team';

  @override
  String get teamName1 => 'Orange team';

  @override
  String get teamName2 => 'Green team';

  @override
  String get teamName3 => 'Pink team';

  @override
  String get reshuffle => 'Reshuffle';

  @override
  String get tapToMove => 'Tap a player to move them to the next team.';

  @override
  String get teamsChosenNote =>
      'Friends picked their teams; anyone who didn\'t was balanced in.';

  @override
  String get letsPlay => 'Let\'s play';

  @override
  String teamTurn(String team) {
    return '$team\'s turn';
  }

  @override
  String namesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count names left',
      one: '1 name left',
      zero: 'Bowl\'s empty',
    );
    return '$_temp0';
  }

  @override
  String turnScore(int points, String team) {
    return '+$points for $team';
  }

  @override
  String get nextTeam => 'Next team';

  @override
  String get seeResults => 'See results';

  @override
  String winnerIs(String team) {
    return '$team wins!';
  }

  @override
  String get itsADraw => 'It\'s a draw!';

  @override
  String get total => 'Total';

  @override
  String get leaveGameTitle => 'Leave this game?';

  @override
  String get leaveGameBody =>
      'The scores will be lost, but the names stay in the bowl.';

  @override
  String get shareCardText => 'From our Family game night';

  @override
  String get shareFailed => 'Couldn\'t share the card.';

  @override
  String moreOnCard(int count) {
    return '+$count more';
  }

  @override
  String get shareThisNight => 'Share this night';

  @override
  String get fewerTeams => 'Fewer teams';

  @override
  String get moreTeams => 'More teams';

  @override
  String get modeFamily => 'Family online';

  @override
  String get modeFamilyDetail =>
      'The classic game on everyone\'s phone: guess who wrote what, and your family grows.';

  @override
  String get familyChatSwitch => 'Family chat';

  @override
  String get familyChatOn => 'Each family gets a private chat to plot in.';

  @override
  String get familyChatOff => 'No chat: families whisper at the table.';

  @override
  String get familyTurnYours => 'Your family\'s turn!';

  @override
  String get familyYouAsk => 'You make the guess.';

  @override
  String familyHeadAsks(String name) {
    return '$name makes the guess.';
  }

  @override
  String familyTurnOther(String name) {
    return '$name\'s family is guessing';
  }

  @override
  String get yourFamily => 'Your family';

  @override
  String familyOf(String name) {
    return '$name\'s family';
  }

  @override
  String get familyHead => 'Head of the family';

  @override
  String get familyWho => 'Who wrote it?';

  @override
  String get familyWhich => 'Which name?';

  @override
  String get familyAsk => 'Ask!';

  @override
  String get familySuggest => 'Suggest to the family';

  @override
  String get familyPickBoth => 'Pick a person and a name first.';

  @override
  String get familyIdeas => 'Family ideas';

  @override
  String get familyNoIdeas =>
      'No ideas yet. Pick a person and a name to suggest one.';

  @override
  String familyIdea(String name, String slip) {
    return '$name wrote “$slip”?';
  }

  @override
  String familyBackers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votes',
      one: '1 vote',
    );
    return '$_temp0';
  }

  @override
  String get familyBackIt => 'Back it';

  @override
  String get familyBacked => 'Backed';

  @override
  String get familyUseIdea => 'Use';

  @override
  String get familyChatHint => 'Only your family sees this';

  @override
  String get familySend => 'Send';

  @override
  String get familyNoMessages => 'No messages yet.';

  @override
  String get familyFamilies => 'Families';

  @override
  String get familyNames => 'The names';

  @override
  String get familyLastGuesses => 'Last guesses';

  @override
  String familyEventCorrect(String asker, String target, String slip) {
    return '$asker caught $target: “$slip”';
  }

  @override
  String familyEventWrong(String asker, String target, String slip) {
    return '$asker asked $target about “$slip”. Nope!';
  }

  @override
  String get familyYouWon => 'Your family won!';

  @override
  String familyWon(String name) {
    return '$name\'s family won!';
  }

  @override
  String get familyWatching =>
      'You\'re watching this one: you didn\'t put a name in.';

  @override
  String get familyLeaveBody =>
      'The game ends on everyone\'s phone, but the names stay in the bowl.';

  @override
  String get familyErrorNotYourTurn =>
      'Hold on, it\'s not your family\'s turn.';

  @override
  String get familyErrorNotHead =>
      'Only the head of your family makes the guess.';

  @override
  String get familyErrorInvalidTarget =>
      'You can’t ask that person. Pick someone else.';

  @override
  String get familyErrorInvalidSlip => 'That name is already out.';

  @override
  String get familyErrorGameOver => 'The game is over.';

  @override
  String get familyErrorChatOff => 'Chat is off in this room.';

  @override
  String get familyErrorEmptyMessage => 'Write something first.';

  @override
  String get familyOffline => 'offline';

  @override
  String familyActingHead(String name) {
    return 'Your family\'s turn! $name is offline, so you ask.';
  }

  @override
  String familyAwayTurn(String name) {
    return '$name\'s family is offline.';
  }

  @override
  String get familyAwayTurnHelp =>
      'Wait for them to come back, or skip their turn.';

  @override
  String get familySkipTurn => 'Skip their turn';

  @override
  String familyClaimTitle(String name) {
    return 'Someone wants back in as $name';
  }

  @override
  String familyClaimBody(String name) {
    return 'Their phone or browser changed. Only let them in if it\'s really $name.';
  }

  @override
  String get familyClaimAllow => 'Let them in';

  @override
  String get familyClaimDeny => 'Not them';

  @override
  String get familyShowCode => 'Show the join code';

  @override
  String get familyShowCodeHelp =>
      'Anyone who dropped out can scan this to get back in.';

  @override
  String get familyNoAddress =>
      'This phone isn\'t on a network right now. Check the Wi-Fi or hotspot.';

  @override
  String get hotspotStopped =>
      'The phone turned the hotspot off. This happens when you leave the app. Tap Create hotspot to turn it back on, then friends scan the new Wi-Fi code.';

  @override
  String get joinGame => 'Join a game';

  @override
  String get joinGameDetail => 'Find a room on this Wi-Fi and hop in.';

  @override
  String get lookingForGames => 'Looking for games on this Wi-Fi…';

  @override
  String get lookingForGamesHelp =>
      'Be on the same Wi-Fi or hotspot as the host, with their room open. You can also scan the host\'s QR code with your camera.';

  @override
  String get cannotLookForGames =>
      'This phone can\'t look for games right now. Scan the host\'s QR code with your camera instead.';

  @override
  String nearbyRoomTitle(String host) {
    return '$host\'s room';
  }

  @override
  String nearbyRoomPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players in',
      one: '1 player in',
      zero: 'Nobody in yet',
    );
    return '$_temp0';
  }

  @override
  String get nearbyRoomPlaying => 'Already playing';

  @override
  String get joinRoomButton => 'Join';

  @override
  String cannotOpenRoom(String url) {
    return 'Couldn\'t open the browser. Open $url yourself.';
  }

  @override
  String get scanHostCode => 'Scan the host\'s code';

  @override
  String get scanHostCodeDetail =>
      'Point your camera at the QR code on the host\'s phone.';

  @override
  String get scanHostCodeHint => 'Fit the host\'s QR code in the square';

  @override
  String get cameraBlocked =>
      'The camera is blocked for this app. Allow it in Settings, or pick a game from the list.';

  @override
  String get cameraFailed =>
      'The camera didn\'t start. Pick a game from the list instead.';

  @override
  String get notAGameCode =>
      'That\'s not a game code. Scan the one on the host\'s lobby screen.';

  @override
  String get wifiCodeTitle => 'That\'s the host\'s Wi-Fi';

  @override
  String wifiCodeDetail(String ssid) {
    return 'Join the Wi-Fi \"$ssid\" in Settings, come back, and scan the game code or pick the room below.';
  }

  @override
  String get copyPassword => 'Copy password';

  @override
  String get passwordCopied => 'Password copied';

  @override
  String get openWifiSettings => 'Open Wi-Fi settings';

  @override
  String get gamesOnThisWifi => 'Games on this Wi-Fi';

  @override
  String get searchingJoke1 => 'Shaking the bowl to see who falls out…';

  @override
  String get searchingJoke2 => 'Knocking on the neighbours\' doors…';

  @override
  String get searchingJoke3 => 'Asking auntie who\'s hosting tonight…';

  @override
  String get searchingJoke4 => 'Checking under the sofa cushions…';

  @override
  String get passPhone => 'Pass the phone';

  @override
  String get passPhoneDetail => 'One phone for everyone. No Wi-Fi needed.';

  @override
  String get passSetupTitle => 'Pass the phone';

  @override
  String get passSetupNote =>
      'No need to list the players. Everyone types their own name when the phone gets to them.';

  @override
  String get passBegin => 'Start';

  @override
  String get passYourTurn => 'Your turn';

  @override
  String get passPrivate => 'Nobody else should see this.';

  @override
  String get passSecretNames => 'Your secret names';

  @override
  String passSecretN(int n) {
    return 'Name $n';
  }

  @override
  String get passTapYourName => 'Played already? Tap your name';

  @override
  String get passIntoBowl => 'Into the bowl';

  @override
  String get passErrorMissingName => 'Type your name first.';

  @override
  String passErrorNameTaken(String name) {
    return '$name is already in. Add a letter, like \"$name M\".';
  }

  @override
  String get passErrorMissingSecret => 'Fill in every name.';

  @override
  String get passErrorTooLong => 'That\'s too long. Keep it shorter.';

  @override
  String get passErrorFull => 'The bowl is full: 30 players at most.';

  @override
  String passNamesIn(String name) {
    return '$name\'s names are in the bowl!';
  }

  @override
  String get passToNext => 'Pass the phone to the next person';

  @override
  String get passImNext => 'I\'m next';

  @override
  String passNeedMore(int count, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in. At least $needed needed to play.',
      one: '1 in. At least $needed needed to play.',
    );
    return '$_temp0';
  }

  @override
  String get passHoldToStart => 'Hold to start the game';

  @override
  String get passHoldHint => 'Press and hold';

  @override
  String get passEveryoneInTitle => 'Is everyone in?';

  @override
  String passEveryoneInBody(int count) {
    return '$count players. Once you start, nobody can add names.';
  }

  @override
  String get passYesStart => 'Yes, start the game';

  @override
  String get passKeepPassing => 'No, keep passing';

  @override
  String get passStopTitle => 'Stop passing?';

  @override
  String get passStopBody => 'The names in the bowl will be lost.';

  @override
  String get passStop => 'Stop';

  @override
  String get passKeepGoing => 'Keep going';

  @override
  String get passReaderTitle => 'Give the phone to whoever reads the names out';

  @override
  String get passReaderDetail => 'Everyone else, listen closely!';

  @override
  String get teamNeedsTwo =>
      'Needs at least 2 players, so the other team has someone to choose from.';

  @override
  String get howToPlayBowl =>
      'Everyone\'s names go into one bowl. Each name comes out once, and the teams take turns.';

  @override
  String get howToPlayTurn =>
      'On your turn, the app shows a name written by someone on another team. Talk it over and pick who wrote it. Right is a point.';

  @override
  String get howToPlayWin =>
      'When the bowl is empty the game ends. The team with the most points wins.';

  @override
  String removePlayerTitle(String name) {
    return 'Take $name out of the room?';
  }

  @override
  String get removePlayerBody =>
      'Their names come out of the bowl. Use this for an old entry left behind when someone joined again on a new phone.';

  @override
  String get removePlayer => 'Take out';

  @override
  String get hostingTitle => 'Hosting a game';

  @override
  String get hostingText =>
      'Friends are playing through this phone. Close the room when you\'re done.';

  @override
  String get howToPlayPokerFace =>
      'When it\'s your name on the screen, keep a straight face!';

  @override
  String get howToPlayDouble =>
      'Sure of your answer? Bet double: +2 if you\'re right, but you lose a point if you\'re wrong.';

  @override
  String get faceOffWhoWrote => 'Who on the other team wrote it?';

  @override
  String get faceOffTalkItOver => 'Talk it over as a team, then pick one.';

  @override
  String get faceOffDouble => 'Bet double';

  @override
  String get faceOffDoubleDetail => 'Right: +2. Wrong: you lose a point.';

  @override
  String get faceOffPickSomeone => 'Pick who wrote it';

  @override
  String faceOffLockIn(String name) {
    return '$name wrote it!';
  }

  @override
  String get faceOffRight => 'Right!';

  @override
  String get faceOffWrong => 'Wrong!';

  @override
  String faceOffWroteIt(String writer, String name) {
    return '$writer wrote “$name”';
  }

  @override
  String faceOffNoPoints(String team) {
    return 'No points for $team';
  }

  @override
  String faceOffLosesPoint(String team) {
    return '$team loses a point';
  }

  @override
  String get faceOffWasDouble => 'It was a double bet.';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get soundEffectsDetail => 'Drumrolls, cheers and sad trombones';

  @override
  String get faceOffSuspense => 'And the answer is…';

  @override
  String get faceOffWritersAtEnd =>
      'Who wrote what stays secret until the end.';

  @override
  String get faceOffWhoWroteWhat => 'Who wrote what';

  @override
  String faceOffTeamSaid(String team, String name) {
    return '$team said $name';
  }

  @override
  String get faceOffDoubleShort => 'double bet';
}
