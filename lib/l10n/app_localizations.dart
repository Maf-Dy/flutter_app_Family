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
