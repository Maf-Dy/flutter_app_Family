import '../domain/room.dart';

/// The HTML friends see in their browser. Self-contained: no external fonts,
/// scripts or images, because on the app's own hotspot there is no internet.
abstract final class JoinPage {
  static const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.mafdy.familygame';

  /// Changes whenever this friend's page should look different, so the page's
  /// poller knows when to reload.
  static String versionFor(Room room, Player? player) =>
      '${room.phase.name}-${room.round}-${player?.hasSubmitted ?? false}';

  static String form(Room room, {Player? player, String? name, List<String>? secrets, SubmissionError? error}) {
    final values = secrets ?? player?.secrets ?? const [];
    final isNewRound = player != null && !player.hasSubmitted && room.round > 1;
    final fields = [
      for (var i = 0; i < room.namesPerPlayer; i++)
        '''
      <div class="field">
        <label for="s$i">${room.namesPerPlayer == 1 ? 'Your secret name' : 'Secret name ${i + 1}'}</label>
        <input id="s$i" name="s$i" class="hand" maxlength="${Room.maxSecretLength}" autocomplete="off"
          autocapitalize="words" required placeholder="Write it on the slip" value="${_esc(i < values.length ? values[i] : '')}">
      </div>''',
    ].join();
    return _layout(
      room: room,
      player: player,
      body:
          '''
    <form method="post" action="/" class="stack">
      <div>
        <span class="label">Category</span>
        <h1>${_esc(room.category)}</h1>
        ${isNewRound ? '<p class="note">New round! Write ${room.namesPerPlayer == 1 ? 'a new name' : 'new names'}.</p>' : ''}
      </div>
      ${error == null ? '' : '<p class="error" role="alert">${_esc(_errorText(error, room))}</p>'}
      <div class="field">
        <label for="name">Your name</label>
        <input id="name" name="name" maxlength="${Room.maxNameLength}" autocomplete="nickname" required
          value="${_esc(name ?? player?.name ?? '')}">
      </div>
      $fields
      <p class="help">Nobody sees who wrote what until the game is over.</p>
      <button type="submit">Drop it in the bowl</button>
    </form>''',
    );
  }

  static String done(Room room, Player player) => _layout(
    room: room,
    player: player,
    body:
        '''
    <div class="center stack">
      <div class="check" aria-hidden="true">✓</div>
      <h1>You're in</h1>
      <p class="muted">Your ${player.secrets.length == 1 ? 'slip is' : 'slips are'} in the bowl.
        <span id="count">${room.slipCount}</span> names so far. Listen for the host to read them out.</p>
      <a class="ghost" href="/?edit=1">Change my ${player.secrets.length == 1 ? 'name' : 'names'}</a>
    </div>''',
  );

  static String reading(Room room, Player? player) => _layout(
    room: room,
    player: player,
    body:
        '''
    <div class="center stack">
      <div class="check" aria-hidden="true">📣</div>
      <h1>Reading has started</h1>
      <p class="muted">${player?.hasSubmitted ?? false ? 'Your name is in the bowl. Listen up!' : 'You missed this round. You can join the next one from this page.'}</p>
    </div>''',
  );

  static String full(Room room) => _layout(
    room: room,
    player: null,
    body: '''
    <div class="center stack">
      <h1>This room is full</h1>
      <p class="muted">Ask the host to start a new room.</p>
    </div>''',
  );

  static String _errorText(SubmissionError error, Room room) => switch (error) {
    SubmissionError.roomClosed => 'Too late, the host has started reading. You can join the next round.',
    SubmissionError.missingName => 'Add your name so the host knows you joined.',
    SubmissionError.missingSecret =>
      room.namesPerPlayer == 1 ? 'Write a secret name first.' : 'Fill in all ${room.namesPerPlayer} secret names.',
    SubmissionError.tooLong => 'That is a bit long. Names can be up to ${Room.maxSecretLength} letters.',
  };

  static String _layout({required Room room, required Player? player, required String body}) =>
      '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="color-scheme" content="light dark">
<title>Family · Room ${_esc(room.code)}</title>
<style>
:root{--bg:#F2F1F8;--card:#fff;--ink:#1D1A33;--muted:#625E7A;--line:#D8D5E8;--primary:#4A3FCF;--on-primary:#fff;
--slip:#FFE7A0;--slip-edge:#E9C868;--slip-ink:#2A2440;--good:#18896D;--error:#B3261E;--accent:#D9480F}
@media (prefers-color-scheme: dark){:root{--bg:#14121F;--card:#1E1B2C;--ink:#ECEAF6;--muted:#A29DBD;--line:#37324F;
--primary:#B3AAFF;--on-primary:#1B1560;--slip:#EFD68A;--slip-edge:#C9AE5C;--good:#4FD1AE;--error:#FFB4AB;--accent:#FF8A50}}
*{box-sizing:border-box}
html,body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.5 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
main{max-width:460px;margin:0 auto;padding:20px 18px 32px;min-height:100vh;display:flex;flex-direction:column;gap:22px}
header{display:flex;justify-content:space-between;align-items:baseline}
.brand{font-weight:800;font-size:22px;letter-spacing:-.03em}
.brand i{display:inline-block;width:7px;height:7px;border-radius:50%;background:var(--accent);margin-left:2px}
.room{font-size:13px;color:var(--muted);font-variant-numeric:tabular-nums}
h1{margin:2px 0 0;font-size:28px;line-height:1.1;letter-spacing:-.02em;text-wrap:balance}
.label{font-size:11px;font-weight:800;letter-spacing:.08em;text-transform:uppercase;color:var(--muted)}
.stack{display:flex;flex-direction:column;gap:16px}
.field label{display:block;font-weight:800;font-size:13px;margin-bottom:6px}
input{width:100%;height:52px;border-radius:14px;border:1.5px solid var(--line);background:var(--card);color:var(--ink);font:inherit;font-size:17px;padding:0 14px}
input:focus{outline:none;border-color:var(--primary);box-shadow:0 0 0 2px var(--primary)}
input.hand{background:var(--slip);color:var(--slip-ink);border-color:var(--slip-edge);font-family:"Segoe Print","Bradley Hand","Chalkboard SE","Comic Sans MS",cursive;font-weight:700;font-size:19px}
input.hand::placeholder{color:var(--slip-ink);opacity:.5}
button{height:54px;border:0;border-radius:16px;background:var(--primary);color:var(--on-primary);font:inherit;font-weight:800;font-size:16px;cursor:pointer}
button:active{transform:scale(.98)}
.help,.muted{color:var(--muted);font-size:14px;margin:0}
.note{margin:8px 0 0;font-weight:700;color:var(--accent)}
.error{margin:0;padding:12px 14px;border-radius:14px;background:color-mix(in srgb,var(--error) 14%,transparent);color:var(--error);font-weight:700}
.center{flex:1;justify-content:center;align-items:center;text-align:center}
.check{width:72px;height:72px;border-radius:50%;background:var(--good);color:#fff;display:grid;place-items:center;font-size:34px;font-weight:800;animation:pop .6s cubic-bezier(.34,1.56,.64,1) both}
@keyframes pop{from{transform:scale(.3);opacity:0}}
.ghost{color:var(--primary);font-weight:800;text-decoration:none;padding:10px}
footer{margin-top:auto;text-align:center;font-size:13px;color:var(--muted)}
footer a{color:var(--primary);font-weight:700}
@media (prefers-reduced-motion: reduce){*{animation:none!important}}
</style>
</head>
<body>
<main>
  <header><span class="brand">family<i></i></span><span class="room">Room ${_esc(room.code)}</span></header>
  $body
  <footer>Want to host your own game? <a href="$playStoreUrl">Get Family on Google Play</a></footer>
</main>
<script>
(function(){
  var version = ${_jsString(versionFor(room, player))};
  setInterval(function(){
    fetch('/status', {cache: 'no-store'}).then(function(r){ return r.json(); }).then(function(s){
      var count = document.getElementById('count');
      if (count) count.textContent = s.count;
      if (s.version !== version && !document.activeElement.matches('input')) location.replace('/');
    }).catch(function(){});
  }, 4000);
})();
</script>
</body>
</html>''';

  static String _esc(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  static String _jsString(String value) => "'${value.replaceAll(RegExp(r'[^a-z0-9-]'), '')}'";
}
