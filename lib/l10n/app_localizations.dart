import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Game'**
  String get appTitle;

  /// No description provided for @wordmark.
  ///
  /// In en, this message translates to:
  /// **'family'**
  String get wordmark;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @youSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String youSuffix(String name);

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Who wrote\nwhat?'**
  String get homeHeadline;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Everyone secretly drops a name in the bowl. Then put the phone down and play.'**
  String get homeTagline;

  /// No description provided for @hostRoom.
  ///
  /// In en, this message translates to:
  /// **'Host a room'**
  String get hostRoom;

  /// No description provided for @hostRoomDetail.
  ///
  /// In en, this message translates to:
  /// **'Friends join from their phone\'s browser. No app, no internet needed.'**
  String get hostRoomDetail;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlay;

  /// No description provided for @howToPlayStep1.
  ///
  /// In en, this message translates to:
  /// **'Everyone scans the QR code and secretly writes a name from the category.'**
  String get howToPlayStep1;

  /// No description provided for @howToPlayStep2.
  ///
  /// In en, this message translates to:
  /// **'The host reads all the names aloud, once or twice.'**
  String get howToPlayStep2;

  /// No description provided for @howToPlayStep3.
  ///
  /// In en, this message translates to:
  /// **'Put the phone down. Take turns asking someone \"Did you write …?\" Guess right and they join your family. The last family standing wins.'**
  String get howToPlayStep3;

  /// No description provided for @howToPlayStep4.
  ///
  /// In en, this message translates to:
  /// **'Afterwards, tap \"Who wrote what?\" to see them all.'**
  String get howToPlayStep4;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'What friends call you'**
  String get yourNameHint;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone\'s language'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربي المصري'**
  String get languageArabic;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @newRoom.
  ///
  /// In en, this message translates to:
  /// **'New room'**
  String get newRoom;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryFamousPeople.
  ///
  /// In en, this message translates to:
  /// **'Famous people'**
  String get categoryFamousPeople;

  /// No description provided for @categoryActors.
  ///
  /// In en, this message translates to:
  /// **'Actors'**
  String get categoryActors;

  /// No description provided for @categorySingers.
  ///
  /// In en, this message translates to:
  /// **'Singers'**
  String get categorySingers;

  /// No description provided for @categoryFootballers.
  ///
  /// In en, this message translates to:
  /// **'Footballers'**
  String get categoryFootballers;

  /// No description provided for @categoryMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get categoryMovies;

  /// No description provided for @categorySeries.
  ///
  /// In en, this message translates to:
  /// **'TV series'**
  String get categorySeries;

  /// No description provided for @categoryCartoons.
  ///
  /// In en, this message translates to:
  /// **'Cartoon characters'**
  String get categoryCartoons;

  /// No description provided for @categoryAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get categoryAnimals;

  /// No description provided for @categoryCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get categoryCountries;

  /// No description provided for @categoryCities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get categoryCities;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryBrands.
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get categoryBrands;

  /// No description provided for @categoryPeopleWeKnow.
  ///
  /// In en, this message translates to:
  /// **'People we all know'**
  String get categoryPeopleWeKnow;

  /// No description provided for @categoryAnything.
  ///
  /// In en, this message translates to:
  /// **'Anything goes'**
  String get categoryAnything;

  /// No description provided for @categoryCustom.
  ///
  /// In en, this message translates to:
  /// **'Your own…'**
  String get categoryCustom;

  /// No description provided for @customCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your own category'**
  String get customCategoryTitle;

  /// No description provided for @customCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Teachers from school'**
  String get customCategoryHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @namesPerPlayer.
  ///
  /// In en, this message translates to:
  /// **'Names per player'**
  String get namesPerPlayer;

  /// No description provided for @namesPerPlayerDetail.
  ///
  /// In en, this message translates to:
  /// **'More names, longer game'**
  String get namesPerPlayerDetail;

  /// No description provided for @fewerNames.
  ///
  /// In en, this message translates to:
  /// **'Fewer names'**
  String get fewerNames;

  /// No description provided for @moreNames.
  ///
  /// In en, this message translates to:
  /// **'More names'**
  String get moreNames;

  /// No description provided for @namesPerPlayerValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 name per player} other{{count} names per player}}'**
  String namesPerPlayerValue(int count);

  /// No description provided for @rules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rules;

  /// No description provided for @sameNameTwice.
  ///
  /// In en, this message translates to:
  /// **'Same name twice'**
  String get sameNameTwice;

  /// No description provided for @sameNameTwiceOn.
  ///
  /// In en, this message translates to:
  /// **'Allowed. Two people writing the same person makes for a funny round.'**
  String get sameNameTwiceOn;

  /// No description provided for @sameNameTwiceOff.
  ///
  /// In en, this message translates to:
  /// **'Not allowed. Whoever writes it second is asked to pick someone else.'**
  String get sameNameTwiceOff;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @checkingWifi.
  ///
  /// In en, this message translates to:
  /// **'Checking Wi-Fi…'**
  String get checkingWifi;

  /// No description provided for @oneMoment.
  ///
  /// In en, this message translates to:
  /// **'One moment.'**
  String get oneMoment;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connectedDetail.
  ///
  /// In en, this message translates to:
  /// **'Friends join the same Wi-Fi, or your hotspot, and scan the code.'**
  String get connectedDetail;

  /// No description provided for @hotspotIsOn.
  ///
  /// In en, this message translates to:
  /// **'Hotspot is on'**
  String get hotspotIsOn;

  /// No description provided for @hotspotIsOnDetail.
  ///
  /// In en, this message translates to:
  /// **'Friends scan the Wi-Fi code first, then the game code.'**
  String get hotspotIsOnDetail;

  /// No description provided for @startingHotspot.
  ///
  /// In en, this message translates to:
  /// **'Starting hotspot…'**
  String get startingHotspot;

  /// No description provided for @noWifiHere.
  ///
  /// In en, this message translates to:
  /// **'No Wi-Fi here'**
  String get noWifiHere;

  /// No description provided for @noWifiCanCreate.
  ///
  /// In en, this message translates to:
  /// **'No problem. The app can make its own hotspot for the room.'**
  String get noWifiCanCreate;

  /// No description provided for @noWifiCannotCreate.
  ///
  /// In en, this message translates to:
  /// **'Turn on Wi-Fi or your phone\'s hotspot. You can do it after opening the room.'**
  String get noWifiCannotCreate;

  /// No description provided for @connectionNote.
  ///
  /// In en, this message translates to:
  /// **'Checked automatically. Nothing goes over the internet; the room lives on this phone.'**
  String get connectionNote;

  /// No description provided for @openRoom.
  ///
  /// In en, this message translates to:
  /// **'Open room'**
  String get openRoom;

  /// No description provided for @openRoomFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the room. Close other apps that share on Wi-Fi and try again.'**
  String get openRoomFailed;

  /// No description provided for @closeRoom.
  ///
  /// In en, this message translates to:
  /// **'Close room'**
  String get closeRoom;

  /// No description provided for @closeRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Close the room?'**
  String get closeRoomTitle;

  /// No description provided for @closeRoomBody.
  ///
  /// In en, this message translates to:
  /// **'Friends\' pages stop working and the names in the bowl are cleared.'**
  String get closeRoomBody;

  /// No description provided for @keepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep open'**
  String get keepOpen;

  /// No description provided for @roomOpen.
  ///
  /// In en, this message translates to:
  /// **'Room open'**
  String get roomOpen;

  /// No description provided for @hotspotOn.
  ///
  /// In en, this message translates to:
  /// **'Hotspot on'**
  String get hotspotOn;

  /// No description provided for @waitingForNetwork.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a network'**
  String get waitingForNetwork;

  /// No description provided for @playersInChip.
  ///
  /// In en, this message translates to:
  /// **'{label} · {count} in'**
  String playersInChip(String label, int count);

  /// No description provided for @linkBroken.
  ///
  /// In en, this message translates to:
  /// **'This phone couldn\'t open its own link, so friends won\'t either. Tap Check again, or use a hotspot.'**
  String get linkBroken;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @linkNotOpening.
  ///
  /// In en, this message translates to:
  /// **'Link not opening?'**
  String get linkNotOpening;

  /// No description provided for @onWifiNow.
  ///
  /// In en, this message translates to:
  /// **'You\'re on Wi-Fi now. Friends on the hotspot stay connected until you switch.'**
  String get onWifiNow;

  /// No description provided for @switchToWifi.
  ///
  /// In en, this message translates to:
  /// **'Switch to Wi-Fi'**
  String get switchToWifi;

  /// No description provided for @inTheBowl.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Bowl\'s empty} =1{1 in the bowl} other{{count} in the bowl}}'**
  String inTheBowl(int count);

  /// No description provided for @readyWhenYouAre.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are'**
  String get readyWhenYouAre;

  /// No description provided for @morePlayersToStart.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more player to start} other{{count} more players to start}}'**
  String morePlayersToStart(int count);

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get startReading;

  /// No description provided for @yourSecretName.
  ///
  /// In en, this message translates to:
  /// **'Your secret name'**
  String get yourSecretName;

  /// No description provided for @yourSecretNameOf.
  ///
  /// In en, this message translates to:
  /// **'Your secret name ({index} of {total})'**
  String yourSecretNameOf(int index, int total);

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @dropInBowl.
  ///
  /// In en, this message translates to:
  /// **'Drop in the bowl'**
  String get dropInBowl;

  /// No description provided for @duplicateHostSecret.
  ///
  /// In en, this message translates to:
  /// **'Someone already put that name in. Pick someone else!'**
  String get duplicateHostSecret;

  /// No description provided for @nameIn.
  ///
  /// In en, this message translates to:
  /// **'Name in'**
  String get nameIn;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @secretsOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String secretsOf(int done, int total);

  /// No description provided for @arrival.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s name is in'**
  String arrival(String name);

  /// No description provided for @scanToJoin.
  ///
  /// In en, this message translates to:
  /// **'Scan to join'**
  String get scanToJoin;

  /// No description provided for @thenScanThis.
  ///
  /// In en, this message translates to:
  /// **'Then scan this'**
  String get thenScanThis;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'Join our Family game: {url}'**
  String shareText(String url);

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @roomCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Room {code}'**
  String roomCodeLabel(String code);

  /// No description provided for @qrForLink.
  ///
  /// In en, this message translates to:
  /// **'QR code for {url}'**
  String qrForLink(String url);

  /// No description provided for @qrForWifi.
  ///
  /// In en, this message translates to:
  /// **'QR code to join the Wi-Fi {ssid}'**
  String qrForWifi(String ssid);

  /// No description provided for @stepJoinWifi.
  ///
  /// In en, this message translates to:
  /// **'Join the Wi-Fi'**
  String get stepJoinWifi;

  /// No description provided for @stepOpenGame.
  ///
  /// In en, this message translates to:
  /// **'Open the game'**
  String get stepOpenGame;

  /// No description provided for @stepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {step}, {label}'**
  String stepLabel(int step, String label);

  /// No description provided for @scanWithCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan with camera'**
  String get scanWithCamera;

  /// No description provided for @wifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get wifi;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @privateHotspotNote.
  ///
  /// In en, this message translates to:
  /// **'This is a private hotspot made by the app, so it doesn\'t show in your phone\'s Hotspot settings. Friends see \"{ssid}\" in their Wi-Fi list.'**
  String privateHotspotNote(String ssid);

  /// No description provided for @noWifiAround.
  ///
  /// In en, this message translates to:
  /// **'No Wi-Fi around'**
  String get noWifiAround;

  /// No description provided for @noWifiAroundCanCreate.
  ///
  /// In en, this message translates to:
  /// **'The app can make a private hotspot. Friends join it by scanning a code. They lose mobile data while connected, which the game doesn\'t need.'**
  String get noWifiAroundCanCreate;

  /// No description provided for @noWifiAroundCannotCreate.
  ///
  /// In en, this message translates to:
  /// **'Turn on your phone\'s hotspot in Settings, then come back here. Friends join the hotspot and scan the code.'**
  String get noWifiAroundCannotCreate;

  /// No description provided for @createHotspot.
  ///
  /// In en, this message translates to:
  /// **'Create hotspot'**
  String get createHotspot;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @hotspotPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Android needs your permission to create the hotspot. On some phones it is called Location; the app never reads where you are.'**
  String get hotspotPermissionDenied;

  /// No description provided for @hotspotPermissionBlocked.
  ///
  /// In en, this message translates to:
  /// **'The permission is turned off for Family Game. Allow it in Settings, then try again.'**
  String get hotspotPermissionBlocked;

  /// No description provided for @hotspotIncompatible.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s own hotspot is on, or this phone can\'t run a second hotspot while on Wi-Fi. Friends can join your hotspot or Wi-Fi instead: tap Check again.'**
  String get hotspotIncompatible;

  /// No description provided for @hotspotNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This phone doesn\'t let apps create a hotspot. Turn on your hotspot in Settings instead.'**
  String get hotspotNotAllowed;

  /// No description provided for @hotspotUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This phone can\'t create a hotspot from an app. Turn on your hotspot in Settings instead.'**
  String get hotspotUnsupported;

  /// No description provided for @hotspotNoAddress.
  ///
  /// In en, this message translates to:
  /// **'The hotspot started, but the room couldn\'t find it. Tap Check again.'**
  String get hotspotNoAddress;

  /// No description provided for @hotspotFailed.
  ///
  /// In en, this message translates to:
  /// **'Android couldn\'t start the hotspot. Make sure Wi-Fi and Location are on, then try again.'**
  String get hotspotFailed;

  /// No description provided for @linkHelpSameWifi.
  ///
  /// In en, this message translates to:
  /// **'Friends must be on the same Wi-Fi as this phone, with mobile data not taking over.'**
  String get linkHelpSameWifi;

  /// No description provided for @linkHelpTypeExactly.
  ///
  /// In en, this message translates to:
  /// **'Type the link exactly, including the number after the colon: {url}'**
  String linkHelpTypeExactly(String url);

  /// No description provided for @linkHelpIsolation.
  ///
  /// In en, this message translates to:
  /// **'Office, hotel, café and guest Wi-Fi often stop phones from seeing each other. The link then never opens, whatever you try. Use this phone\'s hotspot instead.'**
  String get linkHelpIsolation;

  /// No description provided for @useHotspotInstead.
  ///
  /// In en, this message translates to:
  /// **'Use a hotspot instead'**
  String get useHotspotInstead;

  /// No description provided for @leaveRoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this round?'**
  String get leaveRoundTitle;

  /// No description provided for @leaveRoundBody.
  ///
  /// In en, this message translates to:
  /// **'The names stay in the bowl, and friends can change them again.'**
  String get leaveRoundBody;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @readAloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloud;

  /// No description provided for @readAgain.
  ///
  /// In en, this message translates to:
  /// **'Read again'**
  String get readAgain;

  /// No description provided for @readItOut.
  ///
  /// In en, this message translates to:
  /// **'Read it out, then tap Next.'**
  String get readItOut;

  /// No description provided for @lastOne.
  ///
  /// In en, this message translates to:
  /// **'That was the last one.'**
  String get lastOne;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @nextName.
  ///
  /// In en, this message translates to:
  /// **'Next name'**
  String get nextName;

  /// No description provided for @doneReading.
  ///
  /// In en, this message translates to:
  /// **'Done reading'**
  String get doneReading;

  /// No description provided for @nameXofY.
  ///
  /// In en, this message translates to:
  /// **'Name {index} of {total}'**
  String nameXofY(int index, int total);

  /// No description provided for @shuffling.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Shuffling 1 name…} other{Shuffling {count} names…}}'**
  String shuffling(int count);

  /// No description provided for @tapToSkip.
  ///
  /// In en, this message translates to:
  /// **'Tap to skip'**
  String get tapToSkip;

  /// No description provided for @namesOnTheTable.
  ///
  /// In en, this message translates to:
  /// **'Names on the table'**
  String get namesOnTheTable;

  /// No description provided for @boardHint.
  ///
  /// In en, this message translates to:
  /// **'Put the phone down and play. The screen stays on in case anyone forgets a name.'**
  String get boardHint;

  /// No description provided for @whoWroteWhat.
  ///
  /// In en, this message translates to:
  /// **'Who wrote what?'**
  String get whoWroteWhat;

  /// No description provided for @whoWroteHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a name, or reveal them all.'**
  String get whoWroteHint;

  /// No description provided for @thatsAll.
  ///
  /// In en, this message translates to:
  /// **'That\'s all of them!'**
  String get thatsAll;

  /// No description provided for @revealAll.
  ///
  /// In en, this message translates to:
  /// **'Reveal all'**
  String get revealAll;

  /// No description provided for @newRoundSameRoom.
  ///
  /// In en, this message translates to:
  /// **'New round, same room'**
  String get newRoundSameRoom;

  /// No description provided for @endGame.
  ///
  /// In en, this message translates to:
  /// **'End game'**
  String get endGame;

  /// No description provided for @writtenBy.
  ///
  /// In en, this message translates to:
  /// **'{slip}, written by {name}'**
  String writtenBy(String slip, String name);

  /// No description provided for @tapToReveal.
  ///
  /// In en, this message translates to:
  /// **'{slip}. Tap to reveal who wrote it'**
  String tapToReveal(String slip);

  /// No description provided for @gameMode.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get gameMode;

  /// No description provided for @modeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get modeClassic;

  /// No description provided for @modeClassicDetail.
  ///
  /// In en, this message translates to:
  /// **'Read the names aloud, then play at the table.'**
  String get modeClassicDetail;

  /// No description provided for @modeCelebrity.
  ///
  /// In en, this message translates to:
  /// **'Team race'**
  String get modeCelebrity;

  /// No description provided for @modeCelebrityDetail.
  ///
  /// In en, this message translates to:
  /// **'Teams race the clock to guess the names: describe, one word, then act it out.'**
  String get modeCelebrityDetail;

  /// No description provided for @teams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teams;

  /// No description provided for @teamCount.
  ///
  /// In en, this message translates to:
  /// **'Number of teams'**
  String get teamCount;

  /// No description provided for @teamPickLabel.
  ///
  /// In en, this message translates to:
  /// **'Making teams'**
  String get teamPickLabel;

  /// No description provided for @teamPickRandom.
  ///
  /// In en, this message translates to:
  /// **'App shuffles'**
  String get teamPickRandom;

  /// No description provided for @teamPickPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players choose'**
  String get teamPickPlayers;

  /// No description provided for @teamPickHost.
  ///
  /// In en, this message translates to:
  /// **'I arrange'**
  String get teamPickHost;

  /// No description provided for @turnLength.
  ///
  /// In en, this message translates to:
  /// **'Turn length'**
  String get turnLength;

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'{count}s'**
  String secondsShort(int count);

  /// No description provided for @teamName0.
  ///
  /// In en, this message translates to:
  /// **'Purple team'**
  String get teamName0;

  /// No description provided for @teamName1.
  ///
  /// In en, this message translates to:
  /// **'Orange team'**
  String get teamName1;

  /// No description provided for @teamName2.
  ///
  /// In en, this message translates to:
  /// **'Green team'**
  String get teamName2;

  /// No description provided for @teamName3.
  ///
  /// In en, this message translates to:
  /// **'Pink team'**
  String get teamName3;

  /// No description provided for @reshuffle.
  ///
  /// In en, this message translates to:
  /// **'Reshuffle'**
  String get reshuffle;

  /// No description provided for @tapToMove.
  ///
  /// In en, this message translates to:
  /// **'Tap a player to move them to the next team.'**
  String get tapToMove;

  /// No description provided for @teamsChosenNote.
  ///
  /// In en, this message translates to:
  /// **'Friends picked their teams; anyone who didn\'t was balanced in.'**
  String get teamsChosenNote;

  /// No description provided for @letsPlay.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play'**
  String get letsPlay;

  /// No description provided for @roundOf.
  ///
  /// In en, this message translates to:
  /// **'Round {round} of 3'**
  String roundOf(int round);

  /// No description provided for @roundDescribe.
  ///
  /// In en, this message translates to:
  /// **'Describe it'**
  String get roundDescribe;

  /// No description provided for @roundDescribeDetail.
  ///
  /// In en, this message translates to:
  /// **'Say anything except the name itself.'**
  String get roundDescribeDetail;

  /// No description provided for @roundOneWord.
  ///
  /// In en, this message translates to:
  /// **'One word'**
  String get roundOneWord;

  /// No description provided for @roundOneWordDetail.
  ///
  /// In en, this message translates to:
  /// **'Just one word per name. Choose it well!'**
  String get roundOneWordDetail;

  /// No description provided for @roundActOut.
  ///
  /// In en, this message translates to:
  /// **'Act it out'**
  String get roundActOut;

  /// No description provided for @roundActOutDetail.
  ///
  /// In en, this message translates to:
  /// **'No words at all. Only acting and sounds.'**
  String get roundActOutDetail;

  /// No description provided for @startRound.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startRound;

  /// No description provided for @teamTurn.
  ///
  /// In en, this message translates to:
  /// **'{team}\'s turn'**
  String teamTurn(String team);

  /// No description provided for @passPhoneTo.
  ///
  /// In en, this message translates to:
  /// **'Pass the phone to'**
  String get passPhoneTo;

  /// No description provided for @giverHint.
  ///
  /// In en, this message translates to:
  /// **'The rest of the team guesses. Other teams, no peeking!'**
  String get giverHint;

  /// No description provided for @imReady.
  ///
  /// In en, this message translates to:
  /// **'I\'m ready'**
  String get imReady;

  /// No description provided for @gotItGuess.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get gotItGuess;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @namesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Bowl\'s empty} =1{1 name left} other{{count} names left}}'**
  String namesLeft(int count);

  /// No description provided for @secondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second left} other{{count} seconds left}}'**
  String secondsLeft(int count);

  /// No description provided for @timesUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up!'**
  String get timesUp;

  /// No description provided for @bowlEmptied.
  ///
  /// In en, this message translates to:
  /// **'The bowl is empty!'**
  String get bowlEmptied;

  /// No description provided for @turnScore.
  ///
  /// In en, this message translates to:
  /// **'+{points} for {team}'**
  String turnScore(int points, String team);

  /// No description provided for @nextTeam.
  ///
  /// In en, this message translates to:
  /// **'Next team'**
  String get nextTeam;

  /// No description provided for @nextRound.
  ///
  /// In en, this message translates to:
  /// **'Next round'**
  String get nextRound;

  /// No description provided for @seeResults.
  ///
  /// In en, this message translates to:
  /// **'See results'**
  String get seeResults;

  /// No description provided for @winnerIs.
  ///
  /// In en, this message translates to:
  /// **'{team} wins!'**
  String winnerIs(String team);

  /// No description provided for @itsADraw.
  ///
  /// In en, this message translates to:
  /// **'It\'s a draw!'**
  String get itsADraw;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @leaveGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this game?'**
  String get leaveGameTitle;

  /// No description provided for @leaveGameBody.
  ///
  /// In en, this message translates to:
  /// **'The scores will be lost, but the names stay in the bowl.'**
  String get leaveGameBody;

  /// No description provided for @shareCardText.
  ///
  /// In en, this message translates to:
  /// **'From our Family game night'**
  String get shareCardText;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share the card.'**
  String get shareFailed;

  /// No description provided for @moreOnCard.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String moreOnCard(int count);

  /// No description provided for @shareThisNight.
  ///
  /// In en, this message translates to:
  /// **'Share this night'**
  String get shareThisNight;

  /// No description provided for @fewerTeams.
  ///
  /// In en, this message translates to:
  /// **'Fewer teams'**
  String get fewerTeams;

  /// No description provided for @moreTeams.
  ///
  /// In en, this message translates to:
  /// **'More teams'**
  String get moreTeams;

  /// No description provided for @modeFamily.
  ///
  /// In en, this message translates to:
  /// **'Family online'**
  String get modeFamily;

  /// No description provided for @modeFamilyDetail.
  ///
  /// In en, this message translates to:
  /// **'The classic game on everyone\'s phone: guess who wrote what, and your family grows.'**
  String get modeFamilyDetail;

  /// No description provided for @familyChatSwitch.
  ///
  /// In en, this message translates to:
  /// **'Family chat'**
  String get familyChatSwitch;

  /// No description provided for @familyChatOn.
  ///
  /// In en, this message translates to:
  /// **'Each family gets a private chat to plot in.'**
  String get familyChatOn;

  /// No description provided for @familyChatOff.
  ///
  /// In en, this message translates to:
  /// **'No chat: families whisper at the table.'**
  String get familyChatOff;

  /// No description provided for @familyTurnYours.
  ///
  /// In en, this message translates to:
  /// **'Your family\'s turn!'**
  String get familyTurnYours;

  /// No description provided for @familyYouAsk.
  ///
  /// In en, this message translates to:
  /// **'You make the guess.'**
  String get familyYouAsk;

  /// No description provided for @familyHeadAsks.
  ///
  /// In en, this message translates to:
  /// **'{name} makes the guess.'**
  String familyHeadAsks(String name);

  /// No description provided for @familyTurnOther.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s family is guessing'**
  String familyTurnOther(String name);

  /// No description provided for @yourFamily.
  ///
  /// In en, this message translates to:
  /// **'Your family'**
  String get yourFamily;

  /// No description provided for @familyOf.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s family'**
  String familyOf(String name);

  /// No description provided for @familyHead.
  ///
  /// In en, this message translates to:
  /// **'Head of the family'**
  String get familyHead;

  /// No description provided for @familyWho.
  ///
  /// In en, this message translates to:
  /// **'Who wrote it?'**
  String get familyWho;

  /// No description provided for @familyWhich.
  ///
  /// In en, this message translates to:
  /// **'Which name?'**
  String get familyWhich;

  /// No description provided for @familyAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask!'**
  String get familyAsk;

  /// No description provided for @familySuggest.
  ///
  /// In en, this message translates to:
  /// **'Suggest to the family'**
  String get familySuggest;

  /// No description provided for @familyPickBoth.
  ///
  /// In en, this message translates to:
  /// **'Pick a person and a name first.'**
  String get familyPickBoth;

  /// No description provided for @familyIdeas.
  ///
  /// In en, this message translates to:
  /// **'Family ideas'**
  String get familyIdeas;

  /// No description provided for @familyNoIdeas.
  ///
  /// In en, this message translates to:
  /// **'No ideas yet. Pick a person and a name to suggest one.'**
  String get familyNoIdeas;

  /// No description provided for @familyIdea.
  ///
  /// In en, this message translates to:
  /// **'{name} wrote “{slip}”?'**
  String familyIdea(String name, String slip);

  /// No description provided for @familyBackers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 vote} other{{count} votes}}'**
  String familyBackers(int count);

  /// No description provided for @familyBackIt.
  ///
  /// In en, this message translates to:
  /// **'Back it'**
  String get familyBackIt;

  /// No description provided for @familyBacked.
  ///
  /// In en, this message translates to:
  /// **'Backed'**
  String get familyBacked;

  /// No description provided for @familyUseIdea.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get familyUseIdea;

  /// No description provided for @familyChatHint.
  ///
  /// In en, this message translates to:
  /// **'Only your family sees this'**
  String get familyChatHint;

  /// No description provided for @familySend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get familySend;

  /// No description provided for @familyNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get familyNoMessages;

  /// No description provided for @familyFamilies.
  ///
  /// In en, this message translates to:
  /// **'Families'**
  String get familyFamilies;

  /// No description provided for @familyNames.
  ///
  /// In en, this message translates to:
  /// **'The names'**
  String get familyNames;

  /// No description provided for @familyLastGuesses.
  ///
  /// In en, this message translates to:
  /// **'Last guesses'**
  String get familyLastGuesses;

  /// No description provided for @familyEventCorrect.
  ///
  /// In en, this message translates to:
  /// **'{asker} caught {target}: “{slip}”'**
  String familyEventCorrect(String asker, String target, String slip);

  /// No description provided for @familyEventWrong.
  ///
  /// In en, this message translates to:
  /// **'{asker} asked {target} about “{slip}”. Nope!'**
  String familyEventWrong(String asker, String target, String slip);

  /// No description provided for @familyYouWon.
  ///
  /// In en, this message translates to:
  /// **'Your family won!'**
  String get familyYouWon;

  /// No description provided for @familyWon.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s family won!'**
  String familyWon(String name);

  /// No description provided for @familyWatching.
  ///
  /// In en, this message translates to:
  /// **'You\'re watching this one: you didn\'t put a name in.'**
  String get familyWatching;

  /// No description provided for @familyLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'The game ends on everyone\'s phone, but the names stay in the bowl.'**
  String get familyLeaveBody;

  /// No description provided for @familyErrorNotYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Hold on, it\'s not your family\'s turn.'**
  String get familyErrorNotYourTurn;

  /// No description provided for @familyErrorNotHead.
  ///
  /// In en, this message translates to:
  /// **'Only the head of your family makes the guess.'**
  String get familyErrorNotHead;

  /// No description provided for @familyErrorInvalidTarget.
  ///
  /// In en, this message translates to:
  /// **'That person is already in your family.'**
  String get familyErrorInvalidTarget;

  /// No description provided for @familyErrorInvalidSlip.
  ///
  /// In en, this message translates to:
  /// **'That name is already out.'**
  String get familyErrorInvalidSlip;

  /// No description provided for @familyErrorGameOver.
  ///
  /// In en, this message translates to:
  /// **'The game is over.'**
  String get familyErrorGameOver;

  /// No description provided for @familyErrorChatOff.
  ///
  /// In en, this message translates to:
  /// **'Chat is off in this room.'**
  String get familyErrorChatOff;

  /// No description provided for @familyErrorEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Write something first.'**
  String get familyErrorEmptyMessage;

  /// No description provided for @familyOffline.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get familyOffline;

  /// No description provided for @familyActingHead.
  ///
  /// In en, this message translates to:
  /// **'Your family\'s turn! {name} is offline, so you ask.'**
  String familyActingHead(String name);

  /// No description provided for @familyAwayTurn.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s family is offline.'**
  String familyAwayTurn(String name);

  /// No description provided for @familyAwayTurnHelp.
  ///
  /// In en, this message translates to:
  /// **'Wait for them to come back, or skip their turn.'**
  String get familyAwayTurnHelp;

  /// No description provided for @familySkipTurn.
  ///
  /// In en, this message translates to:
  /// **'Skip their turn'**
  String get familySkipTurn;

  /// No description provided for @familyClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Someone wants back in as {name}'**
  String familyClaimTitle(String name);

  /// No description provided for @familyClaimBody.
  ///
  /// In en, this message translates to:
  /// **'Their phone or browser changed. Only let them in if it\'s really {name}.'**
  String familyClaimBody(String name);

  /// No description provided for @familyClaimAllow.
  ///
  /// In en, this message translates to:
  /// **'Let them in'**
  String get familyClaimAllow;

  /// No description provided for @familyClaimDeny.
  ///
  /// In en, this message translates to:
  /// **'Not them'**
  String get familyClaimDeny;

  /// No description provided for @familyShowCode.
  ///
  /// In en, this message translates to:
  /// **'Show the join code'**
  String get familyShowCode;

  /// No description provided for @familyShowCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Anyone who dropped out can scan this to get back in.'**
  String get familyShowCodeHelp;

  /// No description provided for @familyNoAddress.
  ///
  /// In en, this message translates to:
  /// **'This phone isn\'t on a network right now. Check the Wi-Fi or hotspot.'**
  String get familyNoAddress;

  /// No description provided for @hotspotStopped.
  ///
  /// In en, this message translates to:
  /// **'The phone turned the hotspot off. This happens when you leave the app. Tap Create hotspot to turn it back on, then friends scan the new Wi-Fi code.'**
  String get hotspotStopped;

  /// No description provided for @joinGame.
  ///
  /// In en, this message translates to:
  /// **'Join a game'**
  String get joinGame;

  /// No description provided for @joinGameDetail.
  ///
  /// In en, this message translates to:
  /// **'Find a room on this Wi-Fi and hop in.'**
  String get joinGameDetail;

  /// No description provided for @lookingForGames.
  ///
  /// In en, this message translates to:
  /// **'Looking for games on this Wi-Fi…'**
  String get lookingForGames;

  /// No description provided for @lookingForGamesHelp.
  ///
  /// In en, this message translates to:
  /// **'Be on the same Wi-Fi or hotspot as the host, with their room open. You can also scan the host\'s QR code with your camera.'**
  String get lookingForGamesHelp;

  /// No description provided for @cannotLookForGames.
  ///
  /// In en, this message translates to:
  /// **'This phone can\'t look for games right now. Scan the host\'s QR code with your camera instead.'**
  String get cannotLookForGames;

  /// No description provided for @nearbyRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'{host}\'s room'**
  String nearbyRoomTitle(String host);

  /// No description provided for @nearbyRoomPlayers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nobody in yet} =1{1 player in} other{{count} players in}}'**
  String nearbyRoomPlayers(int count);

  /// No description provided for @nearbyRoomPlaying.
  ///
  /// In en, this message translates to:
  /// **'Already playing'**
  String get nearbyRoomPlaying;

  /// No description provided for @joinRoomButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinRoomButton;

  /// No description provided for @cannotOpenRoom.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the browser. Open {url} yourself.'**
  String cannotOpenRoom(String url);

  /// No description provided for @scanHostCode.
  ///
  /// In en, this message translates to:
  /// **'Scan the host\'s code'**
  String get scanHostCode;

  /// No description provided for @scanHostCodeDetail.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the QR code on the host\'s phone.'**
  String get scanHostCodeDetail;

  /// No description provided for @scanHostCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Fit the host\'s QR code in the square'**
  String get scanHostCodeHint;

  /// No description provided for @cameraBlocked.
  ///
  /// In en, this message translates to:
  /// **'The camera is blocked for this app. Allow it in Settings, or pick a game from the list.'**
  String get cameraBlocked;

  /// No description provided for @cameraFailed.
  ///
  /// In en, this message translates to:
  /// **'The camera didn\'t start. Pick a game from the list instead.'**
  String get cameraFailed;

  /// No description provided for @notAGameCode.
  ///
  /// In en, this message translates to:
  /// **'That\'s not a game code. Scan the one on the host\'s lobby screen.'**
  String get notAGameCode;

  /// No description provided for @wifiCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'That\'s the host\'s Wi-Fi'**
  String get wifiCodeTitle;

  /// No description provided for @wifiCodeDetail.
  ///
  /// In en, this message translates to:
  /// **'Join the Wi-Fi \"{ssid}\" in Settings, come back, and scan the game code or pick the room below.'**
  String wifiCodeDetail(String ssid);

  /// No description provided for @copyPassword.
  ///
  /// In en, this message translates to:
  /// **'Copy password'**
  String get copyPassword;

  /// No description provided for @passwordCopied.
  ///
  /// In en, this message translates to:
  /// **'Password copied'**
  String get passwordCopied;

  /// No description provided for @openWifiSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Wi-Fi settings'**
  String get openWifiSettings;

  /// No description provided for @gamesOnThisWifi.
  ///
  /// In en, this message translates to:
  /// **'Games on this Wi-Fi'**
  String get gamesOnThisWifi;

  /// No description provided for @searchingJoke1.
  ///
  /// In en, this message translates to:
  /// **'Shaking the bowl to see who falls out…'**
  String get searchingJoke1;

  /// No description provided for @searchingJoke2.
  ///
  /// In en, this message translates to:
  /// **'Knocking on the neighbours\' doors…'**
  String get searchingJoke2;

  /// No description provided for @searchingJoke3.
  ///
  /// In en, this message translates to:
  /// **'Asking auntie who\'s hosting tonight…'**
  String get searchingJoke3;

  /// No description provided for @searchingJoke4.
  ///
  /// In en, this message translates to:
  /// **'Checking under the sofa cushions…'**
  String get searchingJoke4;

  /// No description provided for @passPhone.
  ///
  /// In en, this message translates to:
  /// **'Pass the phone'**
  String get passPhone;

  /// No description provided for @passPhoneDetail.
  ///
  /// In en, this message translates to:
  /// **'One phone for everyone. No Wi-Fi needed.'**
  String get passPhoneDetail;

  /// No description provided for @passSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Pass the phone'**
  String get passSetupTitle;

  /// No description provided for @passSetupNote.
  ///
  /// In en, this message translates to:
  /// **'No need to list the players. Everyone types their own name when the phone gets to them.'**
  String get passSetupNote;

  /// No description provided for @passBegin.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get passBegin;

  /// No description provided for @passYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get passYourTurn;

  /// No description provided for @passPrivate.
  ///
  /// In en, this message translates to:
  /// **'Nobody else should see this.'**
  String get passPrivate;

  /// No description provided for @passSecretNames.
  ///
  /// In en, this message translates to:
  /// **'Your secret names'**
  String get passSecretNames;

  /// No description provided for @passSecretN.
  ///
  /// In en, this message translates to:
  /// **'Name {n}'**
  String passSecretN(int n);

  /// No description provided for @passTapYourName.
  ///
  /// In en, this message translates to:
  /// **'Played already? Tap your name'**
  String get passTapYourName;

  /// No description provided for @passIntoBowl.
  ///
  /// In en, this message translates to:
  /// **'Into the bowl'**
  String get passIntoBowl;

  /// No description provided for @passErrorMissingName.
  ///
  /// In en, this message translates to:
  /// **'Type your name first.'**
  String get passErrorMissingName;

  /// No description provided for @passErrorNameTaken.
  ///
  /// In en, this message translates to:
  /// **'{name} is already in. Add a letter, like \"{name} M\".'**
  String passErrorNameTaken(String name);

  /// No description provided for @passErrorMissingSecret.
  ///
  /// In en, this message translates to:
  /// **'Fill in every name.'**
  String get passErrorMissingSecret;

  /// No description provided for @passErrorTooLong.
  ///
  /// In en, this message translates to:
  /// **'That\'s too long. Keep it shorter.'**
  String get passErrorTooLong;

  /// No description provided for @passErrorFull.
  ///
  /// In en, this message translates to:
  /// **'The bowl is full: 30 players at most.'**
  String get passErrorFull;

  /// No description provided for @passNamesIn.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s names are in the bowl!'**
  String passNamesIn(String name);

  /// No description provided for @passToNext.
  ///
  /// In en, this message translates to:
  /// **'Pass the phone to the next person'**
  String get passToNext;

  /// No description provided for @passImNext.
  ///
  /// In en, this message translates to:
  /// **'I\'m next'**
  String get passImNext;

  /// No description provided for @passNeedMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 in. At least {needed} needed to play.} other{{count} in. At least {needed} needed to play.}}'**
  String passNeedMore(int count, int needed);

  /// No description provided for @passHoldToStart.
  ///
  /// In en, this message translates to:
  /// **'Hold to start the game'**
  String get passHoldToStart;

  /// No description provided for @passHoldHint.
  ///
  /// In en, this message translates to:
  /// **'Press and hold'**
  String get passHoldHint;

  /// No description provided for @passEveryoneInTitle.
  ///
  /// In en, this message translates to:
  /// **'Is everyone in?'**
  String get passEveryoneInTitle;

  /// No description provided for @passEveryoneInBody.
  ///
  /// In en, this message translates to:
  /// **'{count} players. Once you start, nobody can add names.'**
  String passEveryoneInBody(int count);

  /// No description provided for @passYesStart.
  ///
  /// In en, this message translates to:
  /// **'Yes, start the game'**
  String get passYesStart;

  /// No description provided for @passKeepPassing.
  ///
  /// In en, this message translates to:
  /// **'No, keep passing'**
  String get passKeepPassing;

  /// No description provided for @passStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop passing?'**
  String get passStopTitle;

  /// No description provided for @passStopBody.
  ///
  /// In en, this message translates to:
  /// **'The names in the bowl will be lost.'**
  String get passStopBody;

  /// No description provided for @passStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get passStop;

  /// No description provided for @passKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get passKeepGoing;

  /// No description provided for @passReaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Give the phone to whoever reads the names out'**
  String get passReaderTitle;

  /// No description provided for @passReaderDetail.
  ///
  /// In en, this message translates to:
  /// **'Everyone else, listen closely!'**
  String get passReaderDetail;

  /// No description provided for @teamNeedsTwo.
  ///
  /// In en, this message translates to:
  /// **'Needs at least 2 players: one describes, one guesses.'**
  String get teamNeedsTwo;

  /// No description provided for @pauseTurn.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseTurn;

  /// No description provided for @resumeTurn.
  ///
  /// In en, this message translates to:
  /// **'Carry on'**
  String get resumeTurn;

  /// No description provided for @turnPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get turnPaused;

  /// No description provided for @turnPausedBody.
  ///
  /// In en, this message translates to:
  /// **'The clock is stopped and the name is hidden. Tap Carry on when you\'re ready.'**
  String get turnPausedBody;

  /// No description provided for @carryOnTurn.
  ///
  /// In en, this message translates to:
  /// **'{team} emptied the bowl, so they start the next round with the {seconds} s they had left.'**
  String carryOnTurn(String team, int seconds);

  /// No description provided for @carriedTime.
  ///
  /// In en, this message translates to:
  /// **'{team} starts with {seconds} s left over.'**
  String carriedTime(String team, int seconds);

  /// No description provided for @howToPlayBowl.
  ///
  /// In en, this message translates to:
  /// **'All the names go into one bowl, and the teams take turns.'**
  String get howToPlayBowl;

  /// No description provided for @howToPlayTurn.
  ///
  /// In en, this message translates to:
  /// **'On your turn, one of you holds the phone and gets your team to guess as many names as you can before the clock runs out. Every name guessed is a point.'**
  String get howToPlayTurn;

  /// No description provided for @howToPlaySkip.
  ///
  /// In en, this message translates to:
  /// **'Stuck? Skip it and it goes back in the bowl.'**
  String get howToPlaySkip;

  /// No description provided for @howToPlayRounds.
  ///
  /// In en, this message translates to:
  /// **'When the bowl is empty, every name goes back in for the next round, with harder clues: describe, then one word, then act it out.'**
  String get howToPlayRounds;

  /// No description provided for @howToPlayWhy.
  ///
  /// In en, this message translates to:
  /// **'That\'s the fun: the same names come back, so remember what was said. By round 3 a tiny gesture is enough.'**
  String get howToPlayWhy;

  /// No description provided for @howToPlayWin.
  ///
  /// In en, this message translates to:
  /// **'Most points after 3 rounds wins.'**
  String get howToPlayWin;

  /// No description provided for @teamRaceMoreNames.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Team race needs 1 more name in the bowl} other{Team race needs {count} more names in the bowl}}'**
  String teamRaceMoreNames(int count);

  /// No description provided for @removePlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Take {name} out of the room?'**
  String removePlayerTitle(String name);

  /// No description provided for @removePlayerBody.
  ///
  /// In en, this message translates to:
  /// **'Their names come out of the bowl. Use this for an old entry left behind when someone joined again on a new phone.'**
  String get removePlayerBody;

  /// No description provided for @removePlayer.
  ///
  /// In en, this message translates to:
  /// **'Take out'**
  String get removePlayer;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
