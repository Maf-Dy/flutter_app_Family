import 'dart:convert';

import '../domain/room.dart';
import 'join_strings.dart';
import 'family_page.dart';

/// The HTML friends see in their browser, in their own language ([JoinStrings]).
/// Self-contained: no external fonts, scripts or images, because on the app's
/// own hotspot there is no internet.
abstract final class JoinPage {
  static const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.mafdy.familygame';

  /// Changes whenever this friend's page should look different, so the page's
  /// poller knows when to reload.
  /// The room code and name count are in it too, so a page left open from an
  /// earlier room on the same address reloads instead of sending names to this one.
  static String versionFor(Room room, Player? player) =>
      '${room.code.toLowerCase()}-${room.namesPerPlayer}-${room.phase.name}-${room.round}-${player?.hasSubmitted ?? false}';

  static String form(
    Room room,
    JoinStrings s, {
    Player? player,
    String? name,
    List<String>? secrets,
    SubmissionError? error,
    int? team,
  }) {
    final values = secrets ?? player?.secrets ?? const [];
    final chosenTeam = team ?? player?.team;
    final teamPicker = !room.playersPickTeams
        ? ''
        : '''
      <fieldset class="teams">
        <legend>${_esc(s.pickTeam)}</legend>
        ${[for (var i = 0; i < room.teamSetup.count; i++) '<label class="team" style="--c:var(--p$i)"><input type="radio" name="team" value="$i"${chosenTeam == i ? ' checked' : ''} required><span>${_esc(s.teamName(i))}</span></label>'].join()}
      </fieldset>''';
    final isNewRound = player != null && !player.hasSubmitted && room.round > 1;
    final fields = [
      for (var i = 0; i < room.namesPerPlayer; i++)
        '''
      <div class="field">
        <label for="s$i">${_esc(s.secretLabel(i + 1, room.namesPerPlayer))}</label>
        <input id="s$i" name="s$i" class="hand" maxlength="${Room.maxSecretLength}" autocomplete="off"
          autocapitalize="words" required placeholder="${_esc(s.secretPlaceholder)}" value="${_esc(i < values.length ? values[i] : '')}">
      </div>''',
    ].join();
    return _layout(
      room: room,
      s: s,
      player: player,
      body:
          '''
    <form id="join" method="post" action="/" class="stack">
      <input type="hidden" name="code" value="${_esc(room.code)}">
      <div>
        <span class="label">${_esc(s.categoryLabel)}</span>
        <h1>${_esc(s.category(room.category))}</h1>
        ${isNewRound ? '<p class="note">${_esc(s.newRound(room.namesPerPlayer))}</p>' : ''}
      </div>
      ${error == null ? '' : '<p class="error" role="alert">${_esc(s.error(error, room.namesPerPlayer))}</p>'}
      <div class="field">
        <label for="name">${_esc(s.yourName)}</label>
        <input id="name" name="name" maxlength="${Room.maxNameLength}" autocomplete="nickname" required
          value="${_esc(name ?? player?.name ?? '')}">
      </div>
      $fields
      $teamPicker
      <p class="help">${_esc(s.privacyNote)}</p>
      <button type="submit">${_esc(s.submit)}</button>
    </form>''',
    );
  }

  static String done(Room room, JoinStrings s, Player player) => _layout(
    room: room,
    s: s,
    player: player,
    body:
        '''
    <div class="center stack">
      <div class="drop" aria-hidden="true"><span class="fly"></span><span class="bowl"></span><span class="check">✓</span></div>
      <h1>${_esc(s.youreIn)}</h1>
      ${player.team == null ? '' : '<p class="team-badge" style="--c:var(--p${player.team})">${_esc(s.teamName(player.team!))}</p>'}
      <p class="muted">${s.inTheBowl(player.secrets.length, '<span id="count">${room.slipCount}</span>')}</p>
      <a class="ghost" href="/?edit=1">${_esc(s.changeMine(player.secrets.length))}</a>
    </div>
    ${_confetti()}''',
  );

  static String reading(Room room, JoinStrings s, Player? player) {
    final isIn = player?.hasSubmitted ?? false;
    final race = room.mode == GameMode.celebrity;
    final title = race ? s.raceOn : (isIn ? s.lookUp : s.readingStarted);
    final detail = race ? (isIn ? s.raceWatch : s.missedRound) : (isIn ? s.yoursIsIn : s.missedRound);
    return _layout(
      room: room,
      s: s,
      player: player,
      // Everyone is looking at their own phone; the flash and buzz make them look up.
      bodyClass: isIn ? 'alert' : '',
      body:
          '''
    <div class="center stack">
      <div class="megaphone" aria-hidden="true">${race ? '⏱️' : '📣'}</div>
      <h1 class="${isIn ? 'big' : ''}">${_esc(title)}</h1>
      <p class="muted">${_esc(detail)}</p>
    </div>
    ${isIn ? _buzzOnce('${room.code}-${room.round}') : ''}''',
    );
  }

  /// Buzzes once per round, not on every reload of the page.
  static String _buzzOnce(String key) =>
      '<script>try{var k=${_jsString('buzz-${key.toLowerCase()}')};if(!sessionStorage.getItem(k)){sessionStorage.setItem(k,1);navigator.vibrate&&navigator.vibrate([200,100,200]);}}catch(e){}</script>';

  /// The family game, played on every friend's phone. Friends who didn't put
  /// names in this round watch the board.
  static String family(Room room, JoinStrings s, Player? player) => _layout(
    room: room,
    s: s,
    player: player,
    body: familyBody(s, _esc, hostName: room.hostName),
  );

  static String full(Room room, JoinStrings s) => _layout(
    room: room,
    s: s,
    player: null,
    body:
        '''
    <div class="center stack">
      <h1>${_esc(s.roomFull)}</h1>
      <p class="muted">${_esc(s.askHost)}</p>
    </div>''',
  );

  /// Paper confetti in the players' colours; positions vary by index so the page
  /// needs no script.
  static String _confetti() =>
      '<div class="confetti" aria-hidden="true">${[for (var i = 0; i < 18; i++) '<span style="--x:${(i * 37 + 11) % 100}%;--d:${(0.8 + (i % 6) * 0.07).toStringAsFixed(2)}s;--c:var(--p${i % 6});--r:${(i.isEven ? 1 : -1) * (240 + i * 23)}deg"></span>'].join()}</div>';

  static String _layout({
    required Room room,
    required JoinStrings s,
    required Player? player,
    required String body,
    String bodyClass = '',
  }) =>
      '''<!doctype html>
<html lang="${s.lang}" dir="${s.dir}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="color-scheme" content="light dark">
<title>${_esc(s.brand)} · ${_esc(s.room(room.code))}</title>
<style>
:root{--bg:#F2F1F8;--card:#fff;--ink:#1D1A33;--muted:#625E7A;--line:#D8D5E8;--primary:#4A3FCF;--on-primary:#fff;
--slip:#FFE7A0;--slip-edge:#E9C868;--slip-ink:#2A2440;--good:#18896D;--error:#B3261E;--accent:#D9480F;
--p0:#4A3FCF;--p1:#D9480F;--p2:#18896D;--p3:#B8327A;--p4:#1C7ED6;--p5:#8E6A00}
@media (prefers-color-scheme: dark){:root{--bg:#14121F;--card:#1E1B2C;--ink:#ECEAF6;--muted:#A29DBD;--line:#37324F;
--primary:#B3AAFF;--on-primary:#1B1560;--slip:#EFD68A;--slip-edge:#C9AE5C;--good:#4FD1AE;--error:#FFB4AB;--accent:#FF8A50;
--p0:#8F85FF;--p1:#FF8A50;--p2:#4FD1AE;--p3:#F07AB8;--p4:#5BB0FF;--p5:#E0B94A}}
*{box-sizing:border-box}
html,body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.5 system-ui,-apple-system,"Segoe UI",Roboto,"Noto Sans Arabic",Tahoma,sans-serif}
main{max-width:460px;margin:0 auto;padding:20px 18px 32px;min-height:100vh;display:flex;flex-direction:column;gap:22px}
header{display:flex;justify-content:space-between;align-items:baseline}
.brand{font-weight:800;font-size:22px;letter-spacing:-.03em}
.brand i{display:inline-block;width:7px;height:7px;border-radius:50%;background:var(--accent);margin-inline-start:2px}
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
.teams{border:0;margin:0;padding:0;display:grid;grid-template-columns:1fr 1fr;gap:8px}
.teams legend{font-weight:800;font-size:13px;margin-bottom:6px;padding:0}
.team{position:relative;display:block}
.team input{position:absolute;opacity:0;width:1px;height:1px}
.team span{display:flex;align-items:center;justify-content:center;min-height:48px;border-radius:14px;border:2px solid var(--c);color:var(--c);font-weight:800;padding:6px;text-align:center}
.team input:checked+span{background:var(--c);color:var(--card)}
.team input:focus-visible+span{outline:3px solid var(--ink);outline-offset:2px}
.team-badge{margin:0;padding:6px 14px;border-radius:99px;background:var(--c);color:var(--card);font-weight:800}
.center{flex:1;justify-content:center;align-items:center;text-align:center}
.drop{position:relative;width:130px;height:110px}
.drop .bowl{position:absolute;left:12px;right:12px;bottom:0;height:56px;background:var(--primary);border-radius:8px 8px 64px 64px}
.drop .fly{position:absolute;left:47px;top:6px;width:36px;height:24px;background:var(--slip);border:1px solid var(--slip-edge);border-radius:2px;animation:fly .8s cubic-bezier(.2,0,0,1) both}
@keyframes fly{0%{transform:translateY(-80px) rotate(-30deg);opacity:0}30%{opacity:1}80%{transform:translateY(38px) rotate(10deg);opacity:1}100%{transform:translateY(44px) rotate(8deg);opacity:0}}
.drop .check{position:absolute;inset-inline-end:0;top:0;width:44px;height:44px;border-radius:50%;background:var(--good);color:#fff;display:grid;place-items:center;font-size:22px;font-weight:800;animation:pop .6s .75s cubic-bezier(.34,1.56,.64,1) both}
@keyframes pop{from{transform:scale(.2);opacity:0}}
.confetti{position:fixed;inset:0;pointer-events:none;overflow:hidden}
.confetti span{position:absolute;top:-14px;left:var(--x);width:10px;height:6px;background:var(--c);opacity:0;animation:fall 2.4s var(--d) cubic-bezier(.3,.6,.5,1) forwards}
@keyframes fall{0%{opacity:1;transform:translateY(0) rotate(0)}100%{opacity:0;transform:translateY(100vh) rotate(var(--r))}}
body.alert{animation:flash 1.6s ease-out both}
body.alert main,body.alert .muted,body.alert .room,body.alert footer{animation:flash-ink 1.6s ease-out both}
@keyframes flash{0%,35%{background:var(--primary)}100%{background:var(--bg)}}
@keyframes flash-ink{0%,35%{color:var(--on-primary)}}
.megaphone{font-size:60px;line-height:1;animation:ring 1.1s ease-in-out 3}
@keyframes ring{0%,100%{transform:rotate(0)}20%{transform:rotate(-14deg) scale(1.12)}40%{transform:rotate(12deg) scale(1.12)}60%{transform:rotate(-8deg)}80%{transform:rotate(5deg)}}
h1.big{font-size:44px}
.ghost{color:var(--primary);font-weight:800;text-decoration:none;padding:10px}
footer{margin-top:auto;text-align:center;font-size:13px;color:var(--muted)}
footer a{color:var(--primary);font-weight:700}
$familyCss@media (prefers-reduced-motion: reduce){*{animation:none!important}}
</style>
</head>
<body class="$bodyClass">
<main>
  <header><span class="brand">${_esc(s.brand)}<i></i></span><span class="room">${_esc(s.room(room.code))}</span></header>
  $body
  <footer>${_esc(s.hostYourOwn)} <a href="$playStoreUrl">${_esc(s.getOnPlay)}</a></footer>
</main>
<script>
(function(){
  var version = ${_jsString(versionFor(room, player))};
  var S = ${_jsonString({'rec': s.lobbyReconnecting, 'still': s.lobbyStillOffline(room.hostName), 'back': s.lobbyBack, 'offSubmit': s.lobbyOfflineSubmit})};
  var draftKey = ${_jsString('draft-${room.code.toLowerCase()}')};
  var fails = 0, busy = false, okTimer = null;
  // The family page has its own connection bar.
  var own = !document.getElementById('net');
  var net = document.createElement('p');
  net.className = 'net'; net.setAttribute('role', 'status'); net.hidden = true;
  var main = document.querySelector('main');
  if (own) main.insertBefore(net, main.children[1]);
  var form = document.getElementById('join');
  function say(text, ok){ if (!own) return; clearTimeout(okTimer); net.className = ok ? 'net ok' : 'net'; net.textContent = text; net.hidden = false; }
  function connected(ok){
    if (ok) {
      if (fails >= 2) { say(S.back, true); okTimer = setTimeout(function(){ net.hidden = true; }, 2500); }
      fails = 0;
      return;
    }
    fails++;
    if (fails >= 2) say(fails >= 6 ? S.still : S.rec, false);
  }
  // Keep what the friend typed, so a lost page or a failed send doesn't wipe it.
  function save(){
    if (!form) return;
    try {
      var d = {};
      for (var i = 0; i < form.elements.length; i++) {
        var f = form.elements[i];
        if (f.name && f.type !== 'hidden' && f.type !== 'radio' && f.type !== 'submit') d[f.name] = f.value;
      }
      sessionStorage.setItem(draftKey, JSON.stringify(d));
    } catch (e) {}
  }
  if (form) {
    try {
      var d = JSON.parse(sessionStorage.getItem(draftKey) || 'null');
      if (d) for (var n in d) { var f = form.elements[n]; if (f && !f.value) f.value = d[n]; }
    } catch (e) {}
    form.addEventListener('input', save);
    form.addEventListener('submit', function(e){
      save();
      if (fails >= 2) { e.preventDefault(); say(S.offSubmit, false); }
    });
  } else if (${player?.hasSubmitted ?? false}) {
    try { sessionStorage.removeItem(draftKey); } catch (e) {}
  }
  function poll(){
    if (busy) return;
    busy = true;
    var ctl = window.AbortController ? new AbortController() : null;
    var timer = setTimeout(function(){ if (ctl) ctl.abort(); }, 4000);
    fetch('/status', {cache: 'no-store', signal: ctl ? ctl.signal : undefined}).then(function(r){
      if (!r.ok) throw new Error('status ' + r.status);
      return r.json();
    }).then(function(st){
      connected(true);
      var count = document.getElementById('count');
      if (count) count.textContent = st.count;
      var typing = document.activeElement && document.activeElement.matches && document.activeElement.matches('input');
      if (st.version !== version && !typing) location.replace('/');
    }).catch(function(){ connected(false); }).then(function(){ clearTimeout(timer); busy = false; });
  }
  setInterval(poll, 3000);
  document.addEventListener('visibilitychange', function(){ if (!document.hidden) poll(); });
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

  /// A JSON value safe to drop inside a script tag.
  static String _jsonString(Object value) => jsonEncode(value).replaceAll('<', r'\u003c');
}
