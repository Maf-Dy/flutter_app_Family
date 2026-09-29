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
  String get homeTagline =>
      'كل واحد يرمي اسم في الطبق من غير ما حد يشوف… وبعدين سيبوا الموبايل والعبوا.';

  @override
  String get hostRoom => 'افتح قعدة';

  @override
  String get hostRoomDetail =>
      'صحابك يدخلوا من المتصفح. لا تطبيق ولا إنترنت ولا وجع دماغ.';

  @override
  String get howToPlay => 'إزاي نلعب';

  @override
  String get howToPlayStep1 =>
      'كل واحد يعمل سكان للكود ويكتب اسم من الفئة في السر… محدش يبص!';

  @override
  String get howToPlayStep2 =>
      'صاحب القعدة يقرا كل الأسامي بصوت عالي، مرة ولا اتنين.';

  @override
  String get howToPlayStep3 =>
      'سيبوا الموبايل. كل واحد في دوره يسأل حد: \"إنت اللي كتبت …؟\" لو صح، ينضم لعيلتك. آخر عيلة فاضلة هي اللي تكسب.';

  @override
  String get howToPlayStep4 =>
      'في الآخر دوس على \"مين كتب إيه؟\" واتفرج على الفضايح.';

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
  String get sameNameTwiceOff =>
      'ممنوع. اللي يكتبه تاني هنقوله يدور على حد غيره.';

  @override
  String get connection => 'الاتصال';

  @override
  String get checkingWifi => 'بنشوف الواي فاي…';

  @override
  String get oneMoment => 'ثانية واحدة.';

  @override
  String get connected => 'متوصل';

  @override
  String get connectedDetail =>
      'صحابك يدخلوا نفس الواي فاي أو الهوت سبوت بتاعك ويعملوا سكان للكود.';

  @override
  String get hotspotIsOn => 'الهوت سبوت شغال';

  @override
  String get hotspotIsOnDetail =>
      'صحابك يعملوا سكان لكود الواي فاي الأول، وبعدين كود اللعبة.';

  @override
  String get startingHotspot => 'بنشغل الهوت سبوت…';

  @override
  String get noWifiHere => 'مفيش واي فاي هنا';

  @override
  String get noWifiCanCreate =>
      'ولا يهمك. التطبيق يقدر يعمل هوت سبوت خاص بالقعدة.';

  @override
  String get noWifiCannotCreate =>
      'شغل الواي فاي أو الهوت سبوت بتاع موبايلك. ينفع بعد ما تفتح القعدة كمان.';

  @override
  String get connectionNote =>
      'بنتشيك لوحدنا. مفيش حاجة بتروح على الإنترنت، القعدة كلها على الموبايل ده.';

  @override
  String get openRoom => 'افتح القعدة';

  @override
  String get openRoomFailed =>
      'القعدة مرضيتش تفتح. اقفل أي تطبيق تاني بيشارك على الواي فاي وجرب تاني.';

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
  String get onWifiNow =>
      'إنت على الواي فاي دلوقتي. اللي على الهوت سبوت هيفضلوا متوصلين لحد ما تحوّل.';

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
  String get noWifiAroundCannotCreate =>
      'شغل الهوت سبوت من الإعدادات وارجع هنا. صحابك يدخلوا عليه ويعملوا سكان للكود.';

  @override
  String get createHotspot => 'اعمل هوت سبوت';

  @override
  String get openSettings => 'افتح الإعدادات';

  @override
  String get hotspotPermissionDenied =>
      'أندرويد محتاج إذنك عشان يعمل الهوت سبوت. في موبايلات بيسموه \"الموقع\"، بس متقلقش، التطبيق مش بيعرف إنت فين.';

  @override
  String get hotspotPermissionBlocked =>
      'الإذن مقفول للعبة العيلة. افتحه من الإعدادات وجرب تاني.';

  @override
  String get hotspotIncompatible =>
      'الهوت سبوت بتاعك شغال أصلاً، أو الموبايل مش بيعرف يشغل هوت سبوت تاني وهو على الواي فاي. صحابك يقدروا يدخلوا على الهوت سبوت بتاعك أو الواي فاي: دوس جرب تاني.';

  @override
  String get hotspotNotAllowed =>
      'الموبايل ده مش بيسمح للتطبيقات تعمل هوت سبوت. شغله إنت من الإعدادات.';

  @override
  String get hotspotUnsupported =>
      'الموبايل ده مش بيعرف يعمل هوت سبوت من تطبيق. شغله إنت من الإعدادات.';

  @override
  String get hotspotNoAddress =>
      'الهوت سبوت اشتغل بس القعدة مش لاقياه. دوس جرب تاني.';

  @override
  String get hotspotFailed =>
      'أندرويد معرفش يشغل الهوت سبوت. اتأكد إن الواي فاي والموقع شغالين وجرب تاني.';

  @override
  String get linkHelpSameWifi =>
      'لازم صحابك يبقوا على نفس الواي فاي بتاع الموبايل ده، ومن غير ما الداتا تاخد مكانه.';

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
  String get leaveRoundBody =>
      'الأسامي هتفضل في الطبق، وصحابك يقدروا يغيروها تاني.';

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
  String get boardHint =>
      'حطوا الموبايل وانطلقوا. الشاشة هتفضل منورة لو حد نسي اسم.';

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
  String get modeClassicDetail =>
      'نقرا الأسامي بصوت عالي، وبعدين نلعب على الترابيزة.';

  @override
  String get modeCelebrity => 'فريق قصاد فريق';

  @override
  String get modeCelebrityDetail =>
      'كل فريق بدوره يخمّن مين من الفريق التاني كتب الاسم. واثقين؟ راهنوا بالدبل.';

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
  String get teamsChosenNote =>
      'كل واحد اختار فريقه، واللي ماختارش حطيناه في الفريق الأقل.';

  @override
  String get letsPlay => 'يلا بينا';

  @override
  String teamTurn(String team) {
    return 'دور $team';
  }

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
  String turnScore(int points, String team) {
    return '$team جاب $points 🔥';
  }

  @override
  String get nextTeam => 'الفريق اللي بعده';

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

  @override
  String get modeFamily => 'العيلة أونلاين';

  @override
  String get modeFamilyDetail =>
      'اللعبة الأصلية على موبايلات الكل: خمّن مين كتب إيه، وعيلتك تكبر.';

  @override
  String get familyChatSwitch => 'دردشة العيلة';

  @override
  String get familyChatOn => 'كل عيلة ليها دردشة سرية تتآمر فيها.';

  @override
  String get familyChatOff => 'مفيش دردشة: العيلات تتوشوش على الترابيزة.';

  @override
  String get familyTurnYours => 'دور عيلتك!';

  @override
  String get familyYouAsk => 'انت اللي هتخمّن.';

  @override
  String familyHeadAsks(String name) {
    return 'التخمين على $name.';
  }

  @override
  String familyTurnOther(String name) {
    return 'عيلة $name بتخمّن دلوقتي';
  }

  @override
  String get yourFamily => 'عيلتك';

  @override
  String familyOf(String name) {
    return 'عيلة $name';
  }

  @override
  String get familyHead => 'كبير العيلة';

  @override
  String get familyWho => 'مين اللي كتبه؟';

  @override
  String get familyWhich => 'أنهي اسم؟';

  @override
  String get familyAsk => 'اسأل!';

  @override
  String get familySuggest => 'اقترح على العيلة';

  @override
  String get familyPickBoth => 'اختار الشخص والاسم الأول.';

  @override
  String get familyIdeas => 'اقتراحات العيلة';

  @override
  String get familyNoIdeas => 'مفيش اقتراحات لسه. اختار شخص واسم واقترح.';

  @override
  String familyIdea(String name, String slip) {
    return '$name كتب «$slip»؟';
  }

  @override
  String familyBackers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صوت',
      few: '$count أصوات',
      two: 'صوتين',
      one: 'صوت واحد',
    );
    return '$_temp0';
  }

  @override
  String get familyBackIt => 'أنا معاك';

  @override
  String get familyBacked => 'موافق';

  @override
  String get familyUseIdea => 'خدها';

  @override
  String get familyChatHint => 'محدش هيشوفها غير عيلتك';

  @override
  String get familySend => 'ابعت';

  @override
  String get familyNoMessages => 'مفيش رسايل لسه.';

  @override
  String get familyFamilies => 'العيلات';

  @override
  String get familyNames => 'الأسامي';

  @override
  String get familyLastGuesses => 'آخر التخمينات';

  @override
  String familyEventCorrect(String asker, String target, String slip) {
    return '$asker قفش $target: «$slip»';
  }

  @override
  String familyEventWrong(String asker, String target, String slip) {
    return '$asker سأل $target على «$slip». لأ خالص!';
  }

  @override
  String get familyYouWon => 'عيلتك كسبت يا وحوش!';

  @override
  String familyWon(String name) {
    return 'عيلة $name كسبت!';
  }

  @override
  String get familyWatching => 'انت بتتفرج المرة دي: محطّتش اسم في الطبق.';

  @override
  String get familyLeaveBody =>
      'اللعبة هتقفل عند الكل، بس الأسامي هتفضل في الطبق.';

  @override
  String get familyErrorNotYourTurn => 'استنى، مش دور عيلتك.';

  @override
  String get familyErrorNotHead => 'كبير العيلة بس هو اللي يخمّن.';

  @override
  String get familyErrorInvalidTarget => 'مينفعش تسأل ده. اختار حد تاني.';

  @override
  String get familyErrorInvalidSlip => 'الاسم ده اتكشف خلاص.';

  @override
  String get familyErrorGameOver => 'اللعبة خلصت.';

  @override
  String get familyErrorChatOff => 'الدردشة مقفولة في القعدة دي.';

  @override
  String get familyErrorEmptyMessage => 'اكتب حاجة الأول.';

  @override
  String get familyOffline => 'فاصل';

  @override
  String familyActingHead(String name) {
    return 'دور عيلتك! $name فاصل، فانت اللي هتسأل.';
  }

  @override
  String familyAwayTurn(String name) {
    return 'عيلة $name فاصلة.';
  }

  @override
  String get familyAwayTurnHelp => 'استنوهم يرجعوا، أو عدّي دورهم.';

  @override
  String get familySkipTurn => 'عدّي دورهم';

  @override
  String familyClaimTitle(String name) {
    return 'في حد عايز يرجع باسم $name';
  }

  @override
  String familyClaimBody(String name) {
    return 'موبايله أو المتصفح اتغيّر. دخّله بس لو هو فعلًا $name.';
  }

  @override
  String get familyClaimAllow => 'دخّله';

  @override
  String get familyClaimDeny => 'مش هو';

  @override
  String get familyShowCode => 'ورّي كود الدخول';

  @override
  String get familyShowCodeHelp => 'اللي فصل يقدر يمسح الكود ده ويرجع.';

  @override
  String get familyNoAddress =>
      'الموبايل ده مش على شبكة دلوقتي. شوف الواي فاي أو الهوت سبوت.';

  @override
  String get hotspotStopped =>
      'الموبايل قفل الهوت سبوت. ده بيحصل لما تخرج من التطبيق. دوس اعمل هوت سبوت تاني، وصحابك يسكانوا كود الواي فاي الجديد.';

  @override
  String get joinGame => 'ادخل لعبة';

  @override
  String get joinGameDetail => 'دور على قعدة على نفس الواي فاي وادخل على طول.';

  @override
  String get lookingForGames => 'بندور على ألعاب على الواي فاي ده…';

  @override
  String get lookingForGamesHelp =>
      'خليك على نفس الواي فاي أو الهوت سبوت بتاع اللي فاتح القعدة. أو سكان الكود بتاعه بالكاميرا.';

  @override
  String get cannotLookForGames =>
      'الموبايل ده مش قادر يدور على ألعاب دلوقتي. سكان كود صاحب القعدة بالكاميرا.';

  @override
  String nearbyRoomTitle(String host) {
    return 'قعدة $host';
  }

  @override
  String nearbyRoomPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لاعبين جوه',
      two: 'لاعبين جوه',
      one: 'لاعب واحد جوه',
      zero: 'لسه محدش دخل',
    );
    return '$_temp0';
  }

  @override
  String get nearbyRoomPlaying => 'اللعب بدأ';

  @override
  String get joinRoomButton => 'ادخل';

  @override
  String cannotOpenRoom(String url) {
    return 'المتصفح مفتحش. افتح $url بنفسك.';
  }

  @override
  String get scanHostCode => 'سكان كود صاحب القعدة';

  @override
  String get scanHostCodeDetail =>
      'وجه الكاميرا على الكود اللي على موبايل صاحب القعدة.';

  @override
  String get scanHostCodeHint => 'خلي الكود جوه المربع';

  @override
  String get cameraBlocked =>
      'الكاميرا مقفولة للتطبيق ده. افتحها من الإعدادات، أو اختار لعبة من اللستة.';

  @override
  String get cameraFailed => 'الكاميرا مشتغلتش. اختار لعبة من اللستة.';

  @override
  String get notAGameCode =>
      'ده مش كود لعبة. سكان الكود اللي على شاشة صاحب القعدة.';

  @override
  String get wifiCodeTitle => 'ده الواي فاي بتاع صاحب القعدة';

  @override
  String wifiCodeDetail(String ssid) {
    return 'ادخل على واي فاي \"$ssid\" من الإعدادات، وارجع سكان كود اللعبة أو اختار القعدة من تحت.';
  }

  @override
  String get copyPassword => 'انسخ الباسورد';

  @override
  String get passwordCopied => 'الباسورد اتنسخ';

  @override
  String get openWifiSettings => 'افتح إعدادات الواي فاي';

  @override
  String get gamesOnThisWifi => 'ألعاب على الواي فاي ده';

  @override
  String get searchingJoke1 => 'بنرج البولة نشوف مين هيقع…';

  @override
  String get searchingJoke2 => 'بنخبط على الجيران…';

  @override
  String get searchingJoke3 => 'بنسأل طنط مين فاتح قعدة النهارده…';

  @override
  String get searchingJoke4 => 'بندور تحت مخدات الكنبة…';

  @override
  String get passPhone => 'عدّي الموبايل';

  @override
  String get passPhoneDetail => 'موبايل واحد للكل. من غير واي فاي.';

  @override
  String get passSetupTitle => 'عدّي الموبايل';

  @override
  String get passSetupNote =>
      'مش محتاج تكتب أسامي اللعيبة. كل واحد هيكتب اسمه لما الموبايل يوصله.';

  @override
  String get passBegin => 'يلا نبدأ';

  @override
  String get passYourTurn => 'دورك';

  @override
  String get passPrivate => 'محدش غيرك يبص!';

  @override
  String get passSecretNames => 'أساميك السرية';

  @override
  String passSecretN(int n) {
    return 'الاسم $n';
  }

  @override
  String get passTapYourName => 'لعبت قبل كده؟ دوس على اسمك';

  @override
  String get passIntoBowl => 'ارميهم في الطبق';

  @override
  String get passErrorMissingName => 'اكتب اسمك الأول.';

  @override
  String passErrorNameTaken(String name) {
    return '$name موجود خلاص. زوّد حرف، زي «$name م».';
  }

  @override
  String get passErrorMissingSecret => 'املا كل الأسامي.';

  @override
  String get passErrorTooLong => 'ده طويل أوي. اختصر شوية.';

  @override
  String get passErrorFull => 'الطبق اتملى: 30 لاعب بالكتير.';

  @override
  String passNamesIn(String name) {
    return 'أسامي $name في الطبق!';
  }

  @override
  String get passToNext => 'عدّي الموبايل للي بعدك';

  @override
  String get passImNext => 'الدور عليا';

  @override
  String passNeedMore(int count, int needed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count كتبوا. محتاجين $needed على الأقل.',
      one: 'واحد كتب. محتاجين $needed على الأقل.',
    );
    return '$_temp0';
  }

  @override
  String get passHoldToStart => 'اضغط كتير عشان نبدأ';

  @override
  String get passHoldHint => 'اضغط وسيب صباعك';

  @override
  String get passEveryoneInTitle => 'كله كتب؟';

  @override
  String passEveryoneInBody(int count) {
    return '$count لعيبة. أول ما نبدأ محدش يقدر يزوّد أسامي.';
  }

  @override
  String get passYesStart => 'أيوه، يلا نلعب';

  @override
  String get passKeepPassing => 'لأ، كمّلوا لف';

  @override
  String get passStopTitle => 'نوقف اللف؟';

  @override
  String get passStopBody => 'الأسامي اللي في الطبق هتضيع.';

  @override
  String get passStop => 'وقّف';

  @override
  String get passKeepGoing => 'كمّل';

  @override
  String get passReaderTitle => 'ادّي الموبايل للي هيقرا الأسامي';

  @override
  String get passReaderDetail => 'الباقي ودانكم معانا!';

  @override
  String get teamNeedsTwo =>
      'محتاج اتنين على الأقل، عشان الفريق التاني يلاقي حد يختار منه.';

  @override
  String get howToPlayBowl =>
      'أسامي الكل بتتحط في طبق واحد. كل اسم بيطلع مرة واحدة، والفرق بتلعب بالدور.';

  @override
  String get howToPlayTurn =>
      'في دوركم، الموبايل يطلّع اسم كتبه حد من الفريق التاني. اتشاوروا واختاروا مين كتبه. الصح بنقطة.';

  @override
  String get howToPlayWin =>
      'لما الطبق يفضى اللعبة تخلص. الفريق اللي معاه نقط أكتر يكسب.';

  @override
  String removePlayerTitle(String name) {
    return 'نطلّع $name من القعدة؟';
  }

  @override
  String get removePlayerBody =>
      'أساميه هتطلع من الطبق. استخدمها لو حد دخل تاني من موبايل جديد وفضل اسمه القديم.';

  @override
  String get removePlayer => 'طلّعه';

  @override
  String get hostingTitle => 'إنت فاتح قعدة';

  @override
  String get hostingText =>
      'صحابك بيلعبوا من خلال موبايلك. اقفل القعدة لما تخلّصوا.';

  @override
  String get howToPlayPokerFace =>
      'لو الاسم اللي طالع بتاعك، اعمل نفسك مش واخد بالك!';

  @override
  String get howToPlayDouble =>
      'واثقين من إجابتكم؟ راهنوا بالدبل: +2 لو صح، بس لو غلط تخسروا نقطة.';

  @override
  String get faceOffWhoWrote => 'مين من الفريق التاني كتبه؟';

  @override
  String get faceOffTalkItOver => 'اتشاوروا مع فريقكم، وبعدين اختاروا واحد.';

  @override
  String get faceOffDouble => 'راهن بالدبل';

  @override
  String get faceOffDoubleDetail => 'صح: +2. غلط: تخسروا نقطة.';

  @override
  String get faceOffPickSomeone => 'اختاروا مين كتبه';

  @override
  String faceOffLockIn(String name) {
    return '$name اللي كتبه!';
  }

  @override
  String get faceOffRight => 'صح!';

  @override
  String get faceOffWrong => 'غلط!';

  @override
  String faceOffWroteIt(String writer, String name) {
    return '$writer هو اللي كتب «$name»';
  }

  @override
  String faceOffNoPoints(String team) {
    return 'مفيش نقط لـ$team';
  }

  @override
  String faceOffLosesPoint(String team) {
    return '$team خسر نقطة';
  }

  @override
  String get faceOffWasDouble => 'كان رهان دبل.';

  @override
  String get familyErrorWaiting => 'استنى، فيه حد لازم يرد الأول.';

  @override
  String get familyErrorNotAllowed => 'مينفعش دلوقتي.';

  @override
  String get twistsTitle => 'قوانين القعدة';

  @override
  String get twistsNote => 'تويستات على لعبة العيلة. شغّل اللي يعجبك.';

  @override
  String get twistSecret => 'مسكة في السر';

  @override
  String get twistSecretDetail =>
      'محدش يعرف النتيجة غير عيلتك. اللي يتمسك ينضم في السر ويفضل عامل نفسه حر.';

  @override
  String get twistWanted => 'مطلوب';

  @override
  String get twistWantedDetail =>
      'الأبلكيشن يعلن اسم مطلوب. اللي يمسك صاحبه عيلته تاخد سؤال زيادة.';

  @override
  String get twistRumors => 'إشاعات';

  @override
  String get twistRumorsDetail =>
      'مرة في اللعبة، اطلق إشاعة من غير اسمك. صح أو كدب في كدب.';

  @override
  String get twistLetMeGo => 'فكّك مني!';

  @override
  String get twistLetMeGoDetail =>
      'كارت واحد بيلف في اللعبة. اللي معاه يقدر يلغي سؤال عليه: محدش يعرف كان صح ولا غلط، واللي سأل يخسر دوره وياخد الكارت.';

  @override
  String get familyTurnYouAsk => 'دورك! اسأل لعيلتك.';

  @override
  String familyTurnPlayer(String name) {
    return 'الدور على $name';
  }

  @override
  String familyEventSecret(String asker) {
    return '$asker سأل حد…';
  }

  @override
  String familyEventBlocked(String asker, String target) {
    return '$target قال لـ$asker: فكّك مني!';
  }

  @override
  String get familyEventWantedTag => '(المطلوب!)';

  @override
  String wantedTitle(String name) {
    return 'مطلوب: «$name»';
  }

  @override
  String get wantedDetail => 'امسك اللي كتبه وعيلتك تاخد سؤال زيادة.';

  @override
  String wantedBonus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عيلتك معاها $count أسئلة زيادة',
      two: 'عيلتك معاها سؤالين زيادة',
      one: 'عيلتك معاها سؤال زيادة',
    );
    return '$_temp0';
  }

  @override
  String pendingWaiting(String name) {
    return 'مستنيين $name…';
  }

  @override
  String get pendingWaitingSomeone => 'مستنيين حد يرد…';

  @override
  String letMeGoAsked(String asker, String name) {
    return '$asker بيسألك: انت اللي كتبت «$name»؟';
  }

  @override
  String get letMeGoUse => 'فكّك مني!';

  @override
  String get letMeGoAnswer => 'رد عليه';

  @override
  String get letMeGoHint =>
      'محدش هيعرف كان صح ولا غلط. هو يخسر دوره والكارت يروح له.';

  @override
  String get letMeGoReady => 'كارت «فكّك مني» معاك';

  @override
  String get rumorsTitle => 'إشاعات';

  @override
  String rumorLine(String target, String name) {
    return 'بيقولوا إن $target كتب «$name» 👀';
  }

  @override
  String get rumorSpread => 'اطلق إشاعة';

  @override
  String get rumorHint =>
      'مرة واحدة في اللعبة، ومحدش هيعرف إنها منك. صح أو كدب في كدب.';

  @override
  String get rumorSend => 'اطلقها';

  @override
  String get soundEffects => 'المؤثرات الصوتية';

  @override
  String get soundEffectsDetail => 'طبلة وزغاريط وترومبون حزين';

  @override
  String get faceOffSuspense => 'والإجابة هي…';

  @override
  String get faceOffWritersAtEnd => 'مين كتب إيه سر لحد الآخر، محدش يفتي.';

  @override
  String get faceOffWhoWroteWhat => 'مين كتب إيه';

  @override
  String faceOffTeamSaid(String team, String name) {
    return '$team قالوا $name';
  }

  @override
  String get faceOffDoubleShort => 'رهان دبل';

  @override
  String get awardsTitle => 'جوايز القعدة';

  @override
  String get awardWorstLiar => '🤥 أسوأ كداب';

  @override
  String get awardWorstLiarDetail => 'أول واحد اتقفش';

  @override
  String get awardPokerFace => '😐 وش البوكر';

  @override
  String get awardPokerFaceDetail => 'محدش عرف يقفشه';

  @override
  String get awardWronged => '😤 أكتر واحد اتظلم';

  @override
  String get awardDetective => '🕵️ المخبر';

  @override
  String get familyTreeTitle => 'شجرة العيلة';

  @override
  String awardWrongedDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اتظلم $count مرات',
      two: 'اتظلم مرتين',
      one: 'اتظلم مرة',
    );
    return '$_temp0';
  }

  @override
  String awardDetectiveDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قفش $count',
      two: 'قفش اتنين',
      one: 'قفش واحد',
    );
    return '$_temp0';
  }

  @override
  String faceOffYouSaid(String name) {
    return 'انتو قلتوا $name';
  }

  @override
  String get handwritten => 'بخط إيدك';

  @override
  String get handwrittenOn =>
      'كل واحد يكتب الأسامي بصباعه، وبعدين الكل هيشوف الشخبطة الحقيقية. الخط بيفضح، فغيّر خطك يا فنان!';

  @override
  String get handwrittenOff => 'مقفولة. الأسامي بتتكتب بالكيبورد.';

  @override
  String get inkHint => 'اكتب الاسم هنا بصباعك';

  @override
  String get inkClear => 'امسح';

  @override
  String get inkUndo => 'تراجع';

  @override
  String get inkHidden => 'متخبي عشان محدش يبص';

  @override
  String get inkReveal => 'دوس عشان تكتب';

  @override
  String get handwrittenName => 'اسم مكتوب بخط الإيد';

  @override
  String get inkMissing => 'اكتب كل اسم على ورقته الأول.';

  @override
  String get familyErrorUnknownName =>
      'مفيش اسم زي ده لسه في اللعبة. راجع الكتابة.';

  @override
  String get familyNameHint => 'اكتب الاسم اللي فاكره';

  @override
  String familyLastUnknown(String name) {
    return '👑 $name محدش عرف يقفشه';
  }

  @override
  String familyWinnersSize(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عيلة من $count',
      two: 'عيلة من اتنين',
      one: 'عيلة من واحد',
    );
    return '$_temp0';
  }

  @override
  String get boardHintHidden => 'العب من دماغك! الأسامي مستخبية لحد الآخر.';

  @override
  String letMeGoHeld(String name) {
    return 'الكارت مع $name';
  }
}
