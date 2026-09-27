// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'لعبة العيلة';

  @override
  String get wordmark => 'عيلة';

  @override
  String get you => 'إنت';

  @override
  String youSuffix(String name) {
    return '$name (إنت)';
  }

  @override
  String get homeHeadline => 'مين كتب\nإيه؟';

  @override
  String get homeTagline => 'كل واحد يرمي اسم في الطبق من غير ما حد يشوف… وبعدين سيبوا الموبايل والعبوا.';

  @override
  String get hostRoom => 'افتح قعدة';

  @override
  String get hostRoomDetail => 'صحابك يدخلوا من المتصفح. لا تطبيق ولا إنترنت ولا وجع دماغ.';

  @override
  String get howToPlay => 'إزاي نلعب؟';

  @override
  String get howToPlayStep1 => 'كل واحد يعمل سكان للكود ويكتب اسم من الفئة في السر… محدش يبص!';

  @override
  String get howToPlayStep2 => 'صاحب القعدة يقرا كل الأسامي بصوت عالي، مرة ولا اتنين.';

  @override
  String get howToPlayStep3 =>
      'سيبوا الموبايل. كل واحد في دوره يسأل حد: \"إنت اللي كتبت …؟\" لو صح، ينضم لعيلتك. آخر عيلة فاضلة هي اللي تكسب.';

  @override
  String get howToPlayStep4 => 'في الآخر دوس على \"مين كتب إيه؟\" واتفرج على الفضايح.';

  @override
  String get gotIt => 'تمام كده';

  @override
  String get settings => 'الإعدادات';

  @override
  String get yourName => 'اسمك';

  @override
  String get yourNameHint => 'صحابك بيندهولك بإيه؟';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'لغة الموبايل';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربي المصري';

  @override
  String get done => 'خلاص';

  @override
  String get newRoom => 'قعدة جديدة';

  @override
  String get category => 'الفئة';

  @override
  String get categoryFamousPeople => 'مشاهير';

  @override
  String get categoryActors => 'ممثلين';

  @override
  String get categorySingers => 'مطربين';

  @override
  String get categoryFootballers => 'لعيبة كورة';

  @override
  String get categoryMovies => 'أفلام';

  @override
  String get categorySeries => 'مسلسلات';

  @override
  String get categoryCartoons => 'شخصيات كرتون';

  @override
  String get categoryAnimals => 'حيوانات';

  @override
  String get categoryCountries => 'بلاد';

  @override
  String get categoryCities => 'مدن';

  @override
  String get categoryFood => 'أكلات';

  @override
  String get categoryBrands => 'ماركات';

  @override
  String get categoryPeopleWeKnow => 'ناس كلنا عارفينها';

  @override
  String get categoryAnything => 'أي حاجة وخلاص';

  @override
  String get categoryCustom => 'من دماغك…';

  @override
  String get customCategoryTitle => 'فئة من دماغك';

  @override
  String get customCategoryHint => 'مثلاً: مدرسين المدرسة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get use => 'ماشي';

  @override
  String get namesPerPlayer => 'كام اسم لكل واحد';

  @override
  String get namesPerPlayerDetail => 'أسامي أكتر = لعب أطول';

  @override
  String get fewerNames => 'أقل';

  @override
  String get moreNames => 'أكتر';

  @override
  String namesPerPlayerValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اسم لكل واحد',
      few: '$count أسامي لكل واحد',
      two: 'اسمين لكل واحد',
      one: 'اسم واحد لكل واحد',
    );
    return '$_temp0';
  }

  @override
  String get rules => 'القواعد';

  @override
  String get sameNameTwice => 'نفس الاسم مرتين';

  @override
  String get sameNameTwiceOn => 'مسموح. اتنين يكتبوا نفس الشخص؟ ده أحلى ضحك.';

  @override
  String get sameNameTwiceOff => 'ممنوع. اللي يكتبه تاني هنقوله يدور على حد غيره.';

  @override
  String get connection => 'الاتصال';

  @override
  String get checkingWifi => 'بنشوف الواي فاي…';

  @override
  String get oneMoment => 'ثانية واحدة.';

  @override
  String get connected => 'متوصل';

  @override
  String get connectedDetail => 'صحابك يدخلوا نفس الواي فاي أو الهوت سبوت بتاعك ويعملوا سكان للكود.';

  @override
  String get hotspotIsOn => 'الهوت سبوت شغال';

  @override
  String get hotspotIsOnDetail => 'صحابك يعملوا سكان لكود الواي فاي الأول، وبعدين كود اللعبة.';

  @override
  String get startingHotspot => 'بنشغل الهوت سبوت…';

  @override
  String get noWifiHere => 'مفيش واي فاي هنا';

  @override
  String get noWifiCanCreate => 'ولا يهمك. التطبيق يقدر يعمل هوت سبوت خاص بالقعدة.';

  @override
  String get noWifiCannotCreate => 'شغل الواي فاي أو الهوت سبوت بتاع موبايلك. ينفع بعد ما تفتح القعدة كمان.';

  @override
  String get connectionNote => 'بنتشيك لوحدنا. مفيش حاجة بتروح على الإنترنت، القعدة كلها على الموبايل ده.';

  @override
  String get openRoom => 'افتح القعدة';

  @override
  String get openRoomFailed => 'القعدة مرضيتش تفتح. اقفل أي تطبيق تاني بيشارك على الواي فاي وجرب تاني.';

  @override
  String get closeRoom => 'اقفل القعدة';

  @override
  String get closeRoomTitle => 'تقفل القعدة؟';

  @override
  String get closeRoomBody => 'صفحات صحابك هتقف والأسامي اللي في الطبق هتتمسح.';

  @override
  String get keepOpen => 'لأ خليها';

  @override
  String get roomOpen => 'القعدة مفتوحة';

  @override
  String get hotspotOn => 'الهوت سبوت شغال';

  @override
  String get waitingForNetwork => 'مستنيين شبكة';

  @override
  String playersInChip(String label, int count) {
    return '$label · $count جوه';
  }

  @override
  String get linkBroken =>
      'الموبايل ده نفسه مش عارف يفتح اللينك، يبقى صحابك كمان مش هيعرفوا. دوس جرب تاني، أو استخدم هوت سبوت.';

  @override
  String get checkAgain => 'جرب تاني';

  @override
  String get linkNotOpening => 'اللينك مش بيفتح؟';

  @override
  String get onWifiNow => 'إنت على الواي فاي دلوقتي. اللي على الهوت سبوت هيفضلوا متوصلين لحد ما تحوّل.';

  @override
  String get switchToWifi => 'حوّل على الواي فاي';

  @override
  String inTheBowl(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اسم في الطبق',
      few: '$count أسامي في الطبق',
      two: 'اسمين في الطبق',
      one: 'اسم واحد في الطبق',
      zero: 'الطبق فاضي',
    );
    return '$_temp0';
  }

  @override
  String get readyWhenYouAre => 'جاهزين وقت ما تحب';

  @override
  String morePlayersToStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ناقص $count كمان ونبدأ',
      few: 'ناقص $count كمان ونبدأ',
      two: 'ناقص اتنين كمان ونبدأ',
      one: 'ناقص واحد كمان ونبدأ',
    );
    return '$_temp0';
  }

  @override
  String get startReading => 'يلا نقرا';

  @override
  String get yourSecretName => 'اسمك السري';

  @override
  String yourSecretNameOf(int index, int total) {
    return 'اسمك السري ($index من $total)';
  }

  @override
  String get show => 'ورّي';

  @override
  String get hide => 'خبّي';

  @override
  String get dropInBowl => 'ارميه في الطبق';

  @override
  String get duplicateHostSecret => 'حد سبقك بالاسم ده 😅 اختار حد تاني!';

  @override
  String get nameIn => 'رمى اسمه';

  @override
  String get waiting => 'مستنيينه';

  @override
  String secretsOf(int done, int total) {
    return '$done من $total';
  }

  @override
  String arrival(String name) {
    return '$name رمى اسمه في الطبق';
  }

  @override
  String get scanToJoin => 'سكان وادخل';

  @override
  String get thenScanThis => 'وبعدين سكان هنا';

  @override
  String get share => 'شارك';

  @override
  String get copy => 'انسخ';

  @override
  String shareText(String url) {
    return 'تعالى العب معانا لعبة العيلة: $url';
  }

  @override
  String get linkCopied => 'اللينك اتنسخ';

  @override
  String roomCodeLabel(String code) {
    return 'قعدة $code';
  }

  @override
  String qrForLink(String url) {
    return 'كود QR للينك $url';
  }

  @override
  String qrForWifi(String ssid) {
    return 'كود QR للدخول على الواي فاي $ssid';
  }

  @override
  String get stepJoinWifi => 'ادخل الواي فاي';

  @override
  String get stepOpenGame => 'افتح اللعبة';

  @override
  String stepLabel(int step, String label) {
    return 'خطوة $step، $label';
  }

  @override
  String get scanWithCamera => 'سكان بالكاميرا';

  @override
  String get wifi => 'الواي فاي';

  @override
  String get password => 'الباسورد';

  @override
  String get next => 'اللي بعده';

  @override
  String privateHotspotNote(String ssid) {
    return 'ده هوت سبوت خاص عامله التطبيق، فمش هيظهر في إعدادات الهوت سبوت عندك. صحابك هيلاقوا \"$ssid\" في لستة الواي فاي.';
  }

  @override
  String get noWifiAround => 'مفيش واي فاي حوالينا';

  @override
  String get noWifiAroundCanCreate =>
      'التطبيق يقدر يعمل هوت سبوت خاص. صحابك يدخلوه بسكان كود. النت هيفصل عندهم وهما عليه، واللعبة مش محتاجاه أصلاً.';

  @override
  String get noWifiAroundCannotCreate => 'شغل الهوت سبوت من الإعدادات وارجع هنا. صحابك يدخلوا عليه ويعملوا سكان للكود.';

  @override
  String get createHotspot => 'اعمل هوت سبوت';

  @override
  String get openSettings => 'افتح الإعدادات';

  @override
  String get hotspotPermissionDenied =>
      'أندرويد محتاج إذنك عشان يعمل الهوت سبوت. في موبايلات بيسموه \"الموقع\"، بس متقلقش، التطبيق مش بيعرف إنت فين.';

  @override
  String get hotspotPermissionBlocked => 'الإذن مقفول للعبة العيلة. افتحه من الإعدادات وجرب تاني.';

  @override
  String get hotspotIncompatible =>
      'الهوت سبوت بتاعك شغال أصلاً، أو الموبايل مش بيعرف يشغل هوت سبوت تاني وهو على الواي فاي. صحابك يقدروا يدخلوا على الهوت سبوت بتاعك أو الواي فاي: دوس جرب تاني.';

  @override
  String get hotspotNotAllowed => 'الموبايل ده مش بيسمح للتطبيقات تعمل هوت سبوت. شغله إنت من الإعدادات.';

  @override
  String get hotspotUnsupported => 'الموبايل ده مش بيعرف يعمل هوت سبوت من تطبيق. شغله إنت من الإعدادات.';

  @override
  String get hotspotNoAddress => 'الهوت سبوت اشتغل بس القعدة مش لاقياه. دوس جرب تاني.';

  @override
  String get hotspotFailed => 'أندرويد معرفش يشغل الهوت سبوت. اتأكد إن الواي فاي والموقع شغالين وجرب تاني.';

  @override
  String get linkHelpSameWifi => 'لازم صحابك يبقوا على نفس الواي فاي بتاع الموبايل ده، ومن غير ما الداتا تاخد مكانه.';

  @override
  String linkHelpTypeExactly(String url) {
    return 'اكتبوا اللينك زي ما هو بالظبط، ومعاه الرقم اللي بعد النقطتين: $url';
  }

  @override
  String get linkHelpIsolation =>
      'واي فاي الشغل والفنادق والكافيهات والضيوف ساعات بيمنع الموبايلات تشوف بعض، واللينك عمره ما هيفتح مهما تعمل. استخدم الهوت سبوت أحسن.';

  @override
  String get useHotspotInstead => 'استخدم هوت سبوت بدل كده';

  @override
  String get leaveRoundTitle => 'تسيب الدور ده؟';

  @override
  String get leaveRoundBody => 'الأسامي هتفضل في الطبق، وصحابك يقدروا يغيروها تاني.';

  @override
  String get stay => 'لأ هكمل';

  @override
  String get leave => 'أسيبه';

  @override
  String get readAloud => 'اقرا بصوت عالي';

  @override
  String get readAgain => 'نقرا تاني';

  @override
  String get readItOut => 'اقراه بصوت عالي، ودوس اللي بعده.';

  @override
  String get lastOne => 'كده خلصوا.';

  @override
  String get back => 'رجوع';

  @override
  String get nextName => 'اللي بعده';

  @override
  String get doneReading => 'خلصنا قراية';

  @override
  String nameXofY(int index, int total) {
    return 'اسم $index من $total';
  }

  @override
  String shuffling(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بنقلّب $count اسم…',
      few: 'بنقلّب $count أسامي…',
      two: 'بنقلّب اسمين…',
      one: 'بنقلّب اسم واحد…',
    );
    return '$_temp0';
  }

  @override
  String get tapToSkip => 'دوس عشان تعدّي';

  @override
  String get namesOnTheTable => 'الأسامي على الترابيزة';

  @override
  String get boardHint => 'حطوا الموبايل وانطلقوا. الشاشة هتفضل منورة لو حد نسي اسم.';

  @override
  String get whoWroteWhat => 'مين كتب إيه؟';

  @override
  String get whoWroteHint => 'دوس على اسم، أو افضح الكل مرة واحدة.';

  @override
  String get thatsAll => 'كده الفضايح خلصت! 🎉';

  @override
  String get revealAll => 'افضح الكل';

  @override
  String get newRoundSameRoom => 'دور جديد، نفس القعدة';

  @override
  String get endGame => 'نقفل اللعبة';

  @override
  String writtenBy(String slip, String name) {
    return '$slip، كاتبه $name';
  }

  @override
  String tapToReveal(String slip) {
    return '$slip. دوس عشان تعرف مين كاتبه';
  }

  @override
  String get gameMode => 'اللعبة';

  @override
  String get modeClassic => 'الكلاسيك';

  @override
  String get modeClassicDetail => 'نقرا الأسامي بصوت عالي، وبعدين نلعب على الترابيزة.';

  @override
  String get modeCelebrity => 'سباق الفرق';

  @override
  String get modeCelebrityDetail => 'الفرق بتسابق الوقت وتخمّن الأسامي: وصف، كلمة واحدة، وبعدين تمثيل.';

  @override
  String get teams => 'الفرق';

  @override
  String get teamCount => 'عدد الفرق';

  @override
  String get teamPickLabel => 'تقسيم الفرق';

  @override
  String get teamPickRandom => 'التطبيق يقسّم';

  @override
  String get teamPickPlayers => 'كل واحد يختار';

  @override
  String get teamPickHost => 'أنا أقسّم';

  @override
  String get turnLength => 'وقت الدور';

  @override
  String secondsShort(int count) {
    return '$count ث';
  }

  @override
  String get teamName0 => 'الفريق البنفسجي';

  @override
  String get teamName1 => 'الفريق البرتقاني';

  @override
  String get teamName2 => 'الفريق الأخضر';

  @override
  String get teamName3 => 'الفريق البمبي';

  @override
  String get reshuffle => 'قلّب تاني';

  @override
  String get tapToMove => 'دوس على أي حد عشان تنقله للفريق اللي بعده.';

  @override
  String get teamsChosenNote => 'كل واحد اختار فريقه، واللي ماختارش حطيناه في الفريق الأقل.';

  @override
  String get teamNeedsPlayers => 'كل فريق لازم يبقى فيه حد على الأقل.';

  @override
  String get letsPlay => 'يلا بينا';

  @override
  String roundOf(int round) {
    return 'الجولة $round من 3';
  }

  @override
  String get roundDescribe => 'اوصف';

  @override
  String get roundDescribeDetail => 'قول أي حاجة إلا الاسم نفسه… ولا تتلكك!';

  @override
  String get roundOneWord => 'كلمة واحدة';

  @override
  String get roundOneWordDetail => 'كلمة واحدة بس لكل اسم. اختارها صح!';

  @override
  String get roundActOut => 'مثّلها';

  @override
  String get roundActOutDetail => 'ولا كلمة! تمثيل وأصوات وبس.';

  @override
  String get startRound => 'يلا';

  @override
  String teamTurn(String team) {
    return 'دور $team';
  }

  @override
  String get passPhoneTo => 'ادّي الموبايل لـ';

  @override
  String get giverHint => 'باقي الفريق يخمّن. الفرق التانية ممنوع تبص!';

  @override
  String get imReady => 'أنا جاهز';

  @override
  String get gotItGuess => 'صح!';

  @override
  String get skip => 'عدّي';

  @override
  String namesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فاضل $count اسم',
      few: 'فاضل $count أسامي',
      two: 'فاضل اسمين',
      one: 'فاضل اسم واحد',
      zero: 'الطبق فضي',
    );
    return '$_temp0';
  }

  @override
  String secondsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فاضل $count ثانية',
      few: 'فاضل $count ثواني',
      two: 'فاضل ثانيتين',
      one: 'فاضل ثانية',
    );
    return '$_temp0';
  }

  @override
  String get timesUp => 'الوقت خلص!';

  @override
  String get bowlEmptied => 'الطبق فضي!';

  @override
  String turnScore(int points, String team) {
    return '$team جاب $points 🔥';
  }

  @override
  String get nextTeam => 'الفريق اللي بعده';

  @override
  String get nextRound => 'الجولة اللي بعدها';

  @override
  String get seeResults => 'النتيجة';

  @override
  String winnerIs(String team) {
    return '$team كسب! 🏆';
  }

  @override
  String get itsADraw => 'تعادل! محدش كسب';

  @override
  String get total => 'المجموع';

  @override
  String get leaveGameTitle => 'تسيب اللعبة؟';

  @override
  String get leaveGameBody => 'النتيجة هتضيع، بس الأسامي هتفضل في الطبق.';

  @override
  String get shareCardText => 'من سهرة لعبة العيلة 😂';

  @override
  String get shareFailed => 'معرفناش نشارك الكارت.';

  @override
  String moreOnCard(int count) {
    return 'و$count كمان';
  }

  @override
  String get shareThisNight => 'شارك السهرة';

  @override
  String get fewerTeams => 'فرق أقل';

  @override
  String get moreTeams => 'فرق أكتر';
}
