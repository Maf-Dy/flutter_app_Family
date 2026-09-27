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
  String get homeTagline => 'Everyone secretly drops a name in the bowl. Then put the phone down and play.';

  @override
  String get hostRoom => 'Host a room';

  @override
  String get hostRoomDetail => 'Friends join from their phone\'s browser. No app, no internet needed.';

  @override
  String get howToPlay => 'How to play';

  @override
  String get howToPlayStep1 => 'Everyone scans the QR code and secretly writes a name from the category.';

  @override
  String get howToPlayStep2 => 'The host reads all the names aloud, once or twice.';

  @override
  String get howToPlayStep3 =>
      'Put the phone down. Take turns asking someone \"Did you write …?\" Guess right and they join your family. The last family standing wins.';

  @override
  String get howToPlayStep4 => 'Afterwards, tap \"Who wrote what?\" to see them all.';

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
  String get sameNameTwiceOn => 'Allowed. Two people writing the same person makes for a funny round.';

  @override
  String get sameNameTwiceOff => 'Not allowed. Whoever writes it second is asked to pick someone else.';

  @override
  String get connection => 'Connection';

  @override
  String get checkingWifi => 'Checking Wi-Fi…';

  @override
  String get oneMoment => 'One moment.';

  @override
  String get connected => 'Connected';

  @override
  String get connectedDetail => 'Friends join the same Wi-Fi, or your hotspot, and scan the code.';

  @override
  String get hotspotIsOn => 'Hotspot is on';

  @override
  String get hotspotIsOnDetail => 'Friends scan the Wi-Fi code first, then the game code.';

  @override
  String get startingHotspot => 'Starting hotspot…';

  @override
  String get noWifiHere => 'No Wi-Fi here';

  @override
  String get noWifiCanCreate => 'No problem. The app can make its own hotspot for the room.';

  @override
  String get noWifiCannotCreate => 'Turn on Wi-Fi or your phone\'s hotspot. You can do it after opening the room.';

  @override
  String get connectionNote => 'Checked automatically. Nothing goes over the internet; the room lives on this phone.';

  @override
  String get openRoom => 'Open room';

  @override
  String get openRoomFailed => 'Couldn\'t open the room. Close other apps that share on Wi-Fi and try again.';

  @override
  String get closeRoom => 'Close room';

  @override
  String get closeRoomTitle => 'Close the room?';

  @override
  String get closeRoomBody => 'Friends\' pages stop working and the names in the bowl are cleared.';

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
  String get onWifiNow => 'You\'re on Wi-Fi now. Friends on the hotspot stay connected until you switch.';

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
  String get duplicateHostSecret => 'Someone already put that name in. Pick someone else!';

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
  String get hotspotNoAddress => 'The hotspot started, but the room couldn\'t find it. Tap Check again.';

  @override
  String get hotspotFailed =>
      'Android couldn\'t start the hotspot. Make sure Wi-Fi and Location are on, then try again.';

  @override
  String get linkHelpSameWifi => 'Friends must be on the same Wi-Fi as this phone, with mobile data not taking over.';

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
  String get leaveRoundBody => 'The names stay in the bowl, and friends can change them again.';

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
  String get boardHint => 'Put the phone down and play. The screen stays on in case anyone forgets a name.';

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
}
