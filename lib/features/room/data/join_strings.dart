import '../domain/room.dart';

/// Words on the join page, in the friend's language. The page is served as
/// plain HTML, so it can't use the app's Flutter localizations; these mirror them.
sealed class JoinStrings {
  const JoinStrings();

  /// Picks Arabic when the friend's browser prefers it, English otherwise.
  static JoinStrings forAcceptLanguage(String? header) {
    final first = (header ?? '').split(',').first.trim().toLowerCase();
    return first.startsWith('ar') ? const ArabicJoinStrings() : const EnglishJoinStrings();
  }

  String get lang;
  String get dir;
  String get brand;
  String room(String code);
  String get categoryLabel;
  String category(GameCategory category);
  String newRound(int names);
  String get yourName;
  String secretLabel(int index, int total);
  String get secretPlaceholder;
  String get privacyNote;

  /// Handwritten rooms: the pad's hint, its Clear button, the missing-drawing
  /// error and a nudge to disguise the handwriting.
  String get inkHint;
  String get inkClear;
  String inkMissing(int names);
  String get inkNote;
  String get submit;
  String get youreIn;
  String inTheBowl(int slips, String countHtml);
  String changeMine(int slips);
  String get lookUp;
  String get readingStarted;
  String get yoursIsIn;
  String get missedRound;
  String get raceOn;
  String get raceWatch;
  String get lobbyReconnecting;
  String lobbyStillOffline(String host);
  String get lobbyBack;
  String get lobbyOfflineSubmit;
  String get roomFull;
  String get askHost;
  String error(SubmissionError error, int namesPerPlayer);
  String get hostYourOwn;
  String get getOnPlay;
  String get pickTeam;
  String teamName(int index);

  /// Words for the in-browser family game, looked up by its script. `{name}`
  /// style placeholders are filled in there.
  Map<String, String> get family;
}

final class EnglishJoinStrings extends JoinStrings {
  const EnglishJoinStrings();

  @override
  String get lang => 'en';
  @override
  String get dir => 'ltr';
  @override
  String get brand => 'family';
  @override
  String room(String code) => 'Room $code';
  @override
  String get categoryLabel => 'Category';
  @override
  String category(GameCategory category) => switch (category.preset) {
    null => category.custom ?? '',
    PresetCategory.famousPeople => 'Famous people',
    PresetCategory.actors => 'Actors',
    PresetCategory.singers => 'Singers',
    PresetCategory.footballers => 'Footballers',
    PresetCategory.movies => 'Movies',
    PresetCategory.series => 'TV series',
    PresetCategory.cartoons => 'Cartoon characters',
    PresetCategory.animals => 'Animals',
    PresetCategory.countries => 'Countries',
    PresetCategory.cities => 'Cities',
    PresetCategory.food => 'Food',
    PresetCategory.brands => 'Brands',
    PresetCategory.peopleWeKnow => 'People we all know',
    PresetCategory.anything => 'Anything goes',
  };
  @override
  String newRound(int names) => 'New round! Write ${names == 1 ? 'a new name' : 'new names'}.';
  @override
  String get yourName => 'Your name';
  @override
  String secretLabel(int index, int total) => total == 1 ? 'Your secret name' : 'Secret name $index';
  @override
  String get secretPlaceholder => 'Write it on the slip';
  @override
  String get privacyNote => 'Nobody sees who wrote what until the game is over.';
  @override
  String get inkHint => 'Write the name here with your finger';
  @override
  String get inkClear => 'Clear';
  @override
  String inkMissing(int names) =>
      names == 1 ? 'Write the name with your finger first.' : 'Write all $names names with your finger.';
  @override
  String get inkNote => 'Everyone will see your handwriting later. Disguise it!';
  @override
  String get submit => 'Drop it in the bowl';
  @override
  String get youreIn => 'You’re in';
  @override
  String inTheBowl(int slips, String countHtml) =>
      'Your ${slips == 1 ? 'slip is' : 'slips are'} in the bowl. Names in the bowl so far: $countHtml. '
      'Listen for the host to read them out.';
  @override
  String changeMine(int slips) => 'Change my ${slips == 1 ? 'name' : 'names'}';
  @override
  String get lookUp => 'Look up!';
  @override
  String get readingStarted => 'Reading has started';
  @override
  String get yoursIsIn => 'The host is reading the names. Yours is in there somewhere.';
  @override
  String get missedRound => 'You missed this round. You can join the next one from this page.';
  @override
  String get raceOn => 'The face-off is on!';
  @override
  String get raceWatch =>
      'Gather round the host’s phone with your team. When your name comes up, keep a straight face!';
  @override
  String get lobbyReconnecting => 'Reconnecting… Your names are safe with the host.';
  @override
  String lobbyStillOffline(String host) =>
      'Still can’t reach $host’s phone. Check you’re on the same Wi-Fi. If $host changed Wi-Fi, scan the new code.';
  @override
  String get lobbyBack => 'Connected again.';
  @override
  String get lobbyOfflineSubmit => 'You’re offline. What you typed is kept here: send it when you’re connected again.';
  @override
  String get roomFull => 'This room is full';
  @override
  String get askHost => 'Ask the host to start a new room.';
  @override
  String error(SubmissionError error, int namesPerPlayer) => switch (error) {
    SubmissionError.roomClosed => 'Too late, the host has started reading. You can join the next round.',
    SubmissionError.missingName => 'Add your name so the host knows you joined.',
    SubmissionError.missingSecret =>
      namesPerPlayer == 1 ? 'Write a secret name first.' : 'Fill in all $namesPerPlayer secret names.',
    SubmissionError.tooLong => 'That is a bit long. Names can be up to ${Room.maxSecretLength} letters.',
    SubmissionError.duplicate => 'Someone already put that name in the bowl. Pick someone else!',
    SubmissionError.invalidTeam => 'Pick one of the teams.',
    SubmissionError.nameTaken =>
      'Someone here already goes by that name. Add a letter, or if that was you on another phone, ask the host to take the old one out.',
  };
  @override
  String get hostYourOwn => 'Want to host your own game?';
  @override
  String get getOnPlay => 'Get Family on Google Play';
  @override
  String get pickTeam => 'Your team';
  @override
  String teamName(int index) => const ['Purple team', 'Orange team', 'Green team', 'Pink team'][index % 4];
  @override
  Map<String, String> get family => const {
    'who': 'Who wrote it?',
    'which': 'Which name?',
    'ideas': 'Family ideas',
    'chat': 'Family chat',
    'chatHint': 'Only your family sees this',
    'send': 'Send',
    'families': 'Families',
    'names': 'The names',
    'sep': ', ',
    'youWin': 'Your family won! 🏆',
    'familyWins': '{name}’s family won! 🏆',
    'turnYours': 'Your family’s turn!',
    'youDecide': 'You make the guess.',
    'headDecides': '{name} makes the guess.',
    'turnOther': '{name}’s family is guessing',
    'yourFamily': 'Your family',
    'familyOf': '{name}’s family',
    'youTag': '(you)',
    'ask': 'Ask!',
    'suggest': 'Suggest to the family',
    'noIdeas': 'No ideas yet. Suggest one above.',
    'ideaText': '{name} wrote “{slip}”?',
    'votes': '👍 {count}',
    'voted': 'Backed',
    'vote': 'Back it',
    'use': 'Use',
    'eventCorrect': '{asker} caught {target}: “{slip}” ✅',
    'eventWrong': '{asker} asked {target} about “{slip}”. Nope ❌',
    'err_generic': 'That didn’t work. Try again.',
    'err_pickBoth': 'Pick a person and a name first.',
    'err_notYourTurn': 'Hold on, it’s not your family’s turn.',
    'err_notHead': 'Only the head of your family makes the guess.',
    'err_invalidTarget': 'You can’t ask that person. Pick someone else.',
    'err_invalidSlip': 'That name is already out.',
    'err_gameOver': 'The game is over.',
    'err_chatOff': 'Chat is off in this room.',
    'err_emptyMessage': 'Write something first.',
    'err_notPlaying': 'You’re watching this game. Join the next round!',
    'err_offline': 'Didn’t go through. Check your Wi-Fi and try again.',
    'offline': 'offline',
    'reconnecting': 'Reconnecting… Your game is safe.',
    'stillOffline':
        'Still can’t reach {host}’s phone. Check you’re on the same Wi-Fi. If {host} changed Wi-Fi, scan the new code.',
    'backOnline': 'You’re back in the game!',
    'actingHead': 'Your family’s turn! {name} is offline, so you ask.',
    'familyAway': '{name}’s family is offline. Waiting for them, or for {host} to skip their turn.',
    'claimTitle': 'Were you playing? Tap your name.',
    'claimHelp': '{host} will be asked to let you back in.',
    'claimPending': 'Waiting for {host} to let you back in as {name}…',
    'claimDenied': '{host} said no. You can watch this game.',
    'youAsk': 'Your turn! You ask for your family.',
    'playerAsks': '{name} is asking',
    'eventSecret': '{asker} asked someone…',
    'eventBlocked': '{target} told {asker} “Let me go!”',
    'tagCounter': 'Counter-catch!',
    'tagRevenge': 'Revenge!',
    'tagWanted': '(wanted!)',
    'wantedTitle': 'Wanted: “{name}”',
    'wantedDetail': 'Catch whoever wrote it and your family earns an extra ask.',
    'waiting': 'Waiting for {name}…',
    'waitingSomeone': 'Waiting for someone to answer…',
    'letMeGoAsked': '{asker} asks: did you write “{name}”?',
    'letMeGoUse': 'Let me go!',
    'letMeGoAnswer': 'Answer it',
    'letMeGoHint': 'Once a game. Nobody learns if they were right, and they lose the turn.',
    'cardReady': 'Your “Let me go!” card is ready',
    'cardUsed': 'You used your “Let me go!” card',
    'counterTitle': '{asker} caught you! One shot back:',
    'counterHint': 'Guess who in their family wrote a name. Right, and they all join you.',
    'counterShoot': 'Shoot back',
    'revengeTitle': '{asker} accused you wrongly. Revenge!',
    'revengeHint': 'Which of these did {asker} write? Right, and their whole family joins you.',
    'revengeTake': 'Take revenge',
    'pass': 'Pass',
    'rumors': 'Rumors',
    'rumorLine': 'They say {target} wrote “{name}” 👀',
    'rumorSpread': 'Spread a rumor',
    'rumorHint': 'Once a game, and nobody knows it was you. True or a total lie.',
    'rumorSend': 'Spread it',
    'err_waiting': 'Wait: someone has to answer first.',
    'err_notAllowed': 'You can\'t do that now.',
    'bonus': 'Extra asks saved: {count}',
    'rumorWho': 'About who?',
    'rumorWhich': 'Which name?',
    'awards': 'Awards of the night',
    'award_worstLiar': '🤥 Worst liar',
    'award_pokerFace': '😐 Poker face',
    'award_wronged': '😤 Most wrongly accused',
    'award_detective': '🕵️ The detective',
    'soundOn': '🔊 Sounds on',
    'soundOff': '🔇 Sounds off',
    'sending': 'sending…',
    'gameOverBye': 'The game is over. Thanks for playing!',
  };
}

/// Egyptian Arabic, playful on purpose.
final class ArabicJoinStrings extends JoinStrings {
  const ArabicJoinStrings();

  @override
  String get lang => 'ar';
  @override
  String get dir => 'rtl';
  @override
  String get brand => 'عيلة';
  @override
  String room(String code) => 'قعدة $code';
  @override
  String get categoryLabel => 'الفئة';
  @override
  String category(GameCategory category) => switch (category.preset) {
    null => category.custom ?? '',
    PresetCategory.famousPeople => 'مشاهير',
    PresetCategory.actors => 'ممثلين',
    PresetCategory.singers => 'مطربين',
    PresetCategory.footballers => 'لعيبة كورة',
    PresetCategory.movies => 'أفلام',
    PresetCategory.series => 'مسلسلات',
    PresetCategory.cartoons => 'شخصيات كرتون',
    PresetCategory.animals => 'حيوانات',
    PresetCategory.countries => 'بلاد',
    PresetCategory.cities => 'مدن',
    PresetCategory.food => 'أكلات',
    PresetCategory.brands => 'ماركات',
    PresetCategory.peopleWeKnow => 'ناس كلنا عارفينها',
    PresetCategory.anything => 'أي حاجة وخلاص',
  };
  @override
  String newRound(int names) => 'دور جديد! اكتب ${names == 1 ? 'اسم جديد' : 'أسامي جديدة'}.';
  @override
  String get yourName => 'اسمك';
  @override
  String secretLabel(int index, int total) => total == 1 ? 'اسمك السري' : 'الاسم السري $index';
  @override
  String get secretPlaceholder => 'اكتبه على الورقة';
  @override
  String get privacyNote => 'محدش هيعرف مين كتب إيه غير في آخر اللعبة. متقلقش.';
  @override
  String get inkHint => 'اكتب الاسم هنا بصباعك';
  @override
  String get inkClear => 'امسح';
  @override
  String inkMissing(int names) => names == 1 ? 'اكتب الاسم بصباعك الأول.' : 'اكتب الـ $names أسامي بصباعك.';
  @override
  String get inkNote => 'الكل هيشوف خطك بعدين... غيّره لو تقدر 😉';
  @override
  String get submit => 'ارميه في الطبق';
  @override
  String get youreIn => 'دخلت يا معلم';
  @override
  String inTheBowl(int slips, String countHtml) =>
      '${slips == 1 ? 'ورقتك' : 'ورقك'} في الطبق. عدد الأسامي لحد دلوقتي: $countHtml. '
      'ركز بقى وصاحب القعدة بيقرا.';
  @override
  String changeMine(int slips) => slips == 1 ? 'غيّر اسمي' : 'غيّر أسامي';
  @override
  String get lookUp => 'ارفع راسك!';
  @override
  String get readingStarted => 'القراية بدأت';
  @override
  String get yoursIsIn => 'صاحب القعدة بيقرا الأسامي، واسمك وسطهم في حتة.';
  @override
  String get missedRound => 'الدور ده فاتك. تقدر تدخل الدور الجاي من نفس الصفحة.';
  @override
  String get raceOn => 'فريق قصاد فريق بدأ!';
  @override
  String get raceWatch => 'اتلمّوا حوالين موبايل صاحب القعدة مع فريقكم. ولما اسمك يطلع، اعمل نفسك مش واخد بالك!';
  @override
  String get lobbyReconnecting => 'بنرجّع الاتصال… أساميك في أمان عند صاحب القعدة.';
  @override
  String lobbyStillOffline(String host) =>
      'لسه مش واصلين لموبايل $host. اتأكد إنك على نفس الواي فاي، ولو $host غيّر الواي فاي امسح الكود الجديد.';
  @override
  String get lobbyBack => 'رجع الاتصال.';
  @override
  String get lobbyOfflineSubmit => 'إنت مش متوصل دلوقتي. اللي كتبته محفوظ هنا: ابعته أول ما النت يرجع.';
  @override
  String get roomFull => 'القعدة كاملة';
  @override
  String get askHost => 'قول لصاحب القعدة يفتح قعدة جديدة.';
  @override
  String error(SubmissionError error, int namesPerPlayer) => switch (error) {
    SubmissionError.roomClosed => 'اتأخرت! القراية بدأت خلاص. استنى الدور الجاي.',
    SubmissionError.missingName => 'اكتب اسمك يا نجم عشان نعرف إنك دخلت.',
    SubmissionError.missingSecret =>
      namesPerPlayer == 1 ? 'اكتب اسمك السري الأول.' : 'املى الـ $namesPerPlayer أسامي كلهم.',
    SubmissionError.tooLong => 'طولت شوية! الاسم آخره ${Room.maxSecretLength} حرف.',
    SubmissionError.duplicate => 'حد سبقك بالاسم ده 😅 اكتب حد تاني!',
    SubmissionError.invalidTeam => 'اختار فريق من دول.',
    SubmissionError.nameTaken =>
      'فيه حد هنا بنفس الاسم. زوّد حرف، ولو ده إنت من موبايل تاني قول لصاحب القعدة يطلّع القديم.',
  };
  @override
  String get hostYourOwn => 'عايز تعمل قعدتك؟';
  @override
  String get getOnPlay => 'نزّل لعبة العيلة من جوجل بلاي';
  @override
  String get pickTeam => 'فريقك';
  @override
  String teamName(int index) =>
      const ['الفريق البنفسجي', 'الفريق البرتقاني', 'الفريق الأخضر', 'الفريق البمبي'][index % 4];
  @override
  Map<String, String> get family => const {
    'who': 'مين اللي كتبه؟',
    'which': 'أنهي اسم؟',
    'ideas': 'اقتراحات العيلة',
    'chat': 'دردشة العيلة',
    'chatHint': 'محدش هيشوفها غير عيلتك',
    'send': 'ابعت',
    'families': 'العيلات',
    'names': 'الأسامي',
    'sep': '، ',
    'youWin': 'عيلتك كسبت يا وحوش! 🏆',
    'familyWins': 'عيلة {name} كسبت! 🏆',
    'turnYours': 'دور عيلتك!',
    'youDecide': 'انت اللي هتخمّن.',
    'headDecides': '{name} هو اللي هيخمّن.',
    'turnOther': 'عيلة {name} بتخمّن دلوقتي',
    'yourFamily': 'عيلتك',
    'familyOf': 'عيلة {name}',
    'youTag': '(انت)',
    'ask': 'اسأل!',
    'suggest': 'اقترح على العيلة',
    'noIdeas': 'مفيش اقتراحات لسه. اقترح انت من فوق.',
    'ideaText': '{name} كتب «{slip}»؟',
    'votes': '👍 {count}',
    'voted': 'موافق',
    'vote': 'أنا معاك',
    'use': 'خدها',
    'eventCorrect': '{asker} قفش {target}: «{slip}» ✅',
    'eventWrong': '{asker} سأل {target} على «{slip}». لأ خالص ❌',
    'err_generic': 'حصلت حاجة غلط. جرّب تاني.',
    'err_pickBoth': 'اختار الشخص والاسم الأول.',
    'err_notYourTurn': 'استنى، مش دور عيلتك.',
    'err_notHead': 'كبير العيلة بس هو اللي يخمّن.',
    'err_invalidTarget': 'مينفعش تسأل ده. اختار حد تاني.',
    'err_invalidSlip': 'الاسم ده اتكشف خلاص.',
    'err_gameOver': 'اللعبة خلصت.',
    'err_chatOff': 'الدردشة مقفولة في القعدة دي.',
    'err_emptyMessage': 'اكتب حاجة الأول.',
    'err_notPlaying': 'انت بتتفرج المرة دي. ادخل الدور الجاي!',
    'err_offline': 'موصلتش. اتأكد من الواي فاي وجرّب تاني.',
    'offline': 'فاصل',
    'reconnecting': 'بنرجّع الاتصال… لعبتك في أمان.',
    'stillOffline':
        'لسه مش واصلين لموبايل {host}. اتأكد إنك على نفس الواي فاي. لو {host} غيّر الواي فاي، امسح الكود الجديد.',
    'backOnline': 'رجعت اللعبة تاني!',
    'actingHead': 'دور عيلتك! {name} فاصل، فانت اللي هتسأل.',
    'familyAway': 'عيلة {name} فاصلة. مستنيينهم يرجعوا، أو {host} يعدّي دورهم.',
    'claimTitle': 'كنت بتلعب؟ دوس على اسمك.',
    'claimHelp': 'هنسأل {host} يدخّلك تاني.',
    'claimPending': 'مستنيين {host} يرجّعك باسم {name}…',
    'claimDenied': '{host} قال لأ. تقدر تتفرج على اللعبة دي.',
    'youAsk': 'دورك! اسأل لعيلتك.',
    'playerAsks': 'الدور على {name}',
    'eventSecret': '{asker} سأل حد…',
    'eventBlocked': '{target} قال لـ{asker}: فكّك مني!',
    'tagCounter': 'رد المسكة!',
    'tagRevenge': 'تار!',
    'tagWanted': '(المطلوب!)',
    'wantedTitle': 'مطلوب: «{name}»',
    'wantedDetail': 'امسك اللي كتبه وعيلتك تاخد سؤال زيادة.',
    'waiting': 'مستنيين {name}…',
    'waitingSomeone': 'مستنيين حد يرد…',
    'letMeGoAsked': '{asker} بيسألك: انت اللي كتبت «{name}»؟',
    'letMeGoUse': 'فكّك مني!',
    'letMeGoAnswer': 'رد عليه',
    'letMeGoHint': 'مرة واحدة في اللعبة. محدش هيعرف كان صح ولا غلط، وهو يخسر دوره.',
    'cardReady': 'كارت «فكّك مني» معاك',
    'cardUsed': 'استخدمت كارت «فكّك مني»',
    'counterTitle': '{asker} قفشك! ليك طلقة واحدة:',
    'counterHint': 'خمّن مين في عيلته كتب اسم. لو صح، كلهم ينضموا لك.',
    'counterShoot': 'رد المسكة',
    'revengeTitle': '{asker} اتهمك ظلم. خد تارك!',
    'revengeHint': 'أنهي اسم فيهم {asker} كتبه؟ لو صح، عيلته كلها تنضم لك.',
    'revengeTake': 'خد تارك',
    'pass': 'عدّي',
    'rumors': 'إشاعات',
    'rumorLine': 'بيقولوا إن {target} كتب «{name}» 👀',
    'rumorSpread': 'اطلق إشاعة',
    'rumorHint': 'مرة واحدة في اللعبة، ومحدش هيعرف إنها منك. صح أو كدب في كدب.',
    'rumorSend': 'اطلقها',
    'err_waiting': 'استنى، فيه حد لازم يرد الأول.',
    'err_notAllowed': 'مينفعش دلوقتي.',
    'bonus': 'أسئلة زيادة معاكم: {count}',
    'rumorWho': 'على مين؟',
    'rumorWhich': 'أنهي اسم؟',
    'awards': 'جوايز القعدة',
    'award_worstLiar': '🤥 أسوأ كداب',
    'award_pokerFace': '😐 وش البوكر',
    'award_wronged': '😤 أكتر واحد اتظلم',
    'award_detective': '🕵️ المخبر',
    'soundOn': '🔊 الصوت شغال',
    'soundOff': '🔇 الصوت مقفول',
    'sending': 'بيتبعت…',
    'gameOverBye': 'اللعبة خلصت. شكرًا إنكم لعبتوا!',
  };
}
