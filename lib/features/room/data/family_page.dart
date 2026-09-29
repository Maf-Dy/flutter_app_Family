import 'dart:convert';

import 'browser_sounds.dart';
import 'join_strings.dart';

/// The body of a friend's page while a family game runs: their family, the
/// guess or idea pickers, family ideas and chat, and the public board.
///
/// Static markup with ids; the script fills it from `/game` every 1.5 s, and
/// only ever writes user text with `textContent`, never as HTML.
String familyBody(JoinStrings s, String Function(String) esc, {required String hostName}) {
  // JSON is valid script, as long as nothing in it can close the <script> tag or open a comment.
  final strings = jsonEncode(s.family).replaceAll('<', r'\u003c');
  final host = jsonEncode(hostName).replaceAll('<', r'\u003c');
  return '''
    <div class="stack fam">
      <div id="net" class="net" role="status" aria-live="polite" hidden></div>
      <div id="banner" class="banner" role="status" aria-live="polite"></div>
      <button id="sound" type="button" class="soundb"></button>
      <section class="card stack twist" id="pendCard" hidden>
        <h2 id="pendTitle"></h2>
        <p class="help" id="pendHelp"></p>
        <div class="field" id="pendWhoF"><label for="pendWho">${esc(s.family['who']!)}</label><select id="pendWho"></select></div>
        <div id="pendSlips" class="chips"></div>
        <p id="pendErr" class="error" hidden></p>
        <div id="pendBtns" class="row"></div>
      </section>
      <section class="card wanted" id="wantedCard" hidden>
        <h2 id="wantedTitle"></h2>
        <p class="help" id="wantedHelp"></p>
      </section>
      <section class="card" id="awardsCard" hidden>
        <h2>${esc(s.family['awards']!)}</h2>
        <div id="awards" class="list"></div>
      </section>
      <section class="card" id="claimCard" hidden>
        <h2 id="claimTitle"></h2>
        <p class="help" id="claimHelp"></p>
        <div id="claimList" class="chips"></div>
        <p id="claimErr" class="error" hidden></p>
      </section>
      <section class="card" id="mineCard">
        <h2 id="mineTitle"></h2>
        <div id="mine" class="chips"></div>
        <p class="help" id="cardLine" hidden></p>
      </section>
      <section class="card stack" id="actCard">
        <div class="field"><label for="who">${esc(s.family['who']!)}</label><select id="who"></select></div>
        <div class="field"><label for="which">${esc(s.family['which']!)}</label><select id="which"></select></div>
        <p id="err" class="error" hidden></p>
        <button id="go" type="button"></button>
      </section>
      <section class="card stack" id="rumorCard" hidden>
        <h2>${esc(s.family['rumors']!)}</h2>
        <div id="rumorList" class="list"></div>
        <details id="rumorForm">
          <summary id="rumorOpen">${esc(s.family['rumorSpread']!)}</summary>
          <p class="help">${esc(s.family['rumorHint']!)}</p>
          <div class="field"><label for="rumorWho">${esc(s.family['rumorWho']!)}</label><select id="rumorWho"></select></div>
          <div class="field"><label for="rumorWhich">${esc(s.family['rumorWhich']!)}</label><select id="rumorWhich"></select></div>
          <p id="rumorErr" class="error" hidden></p>
          <button id="rumorGo" type="button">${esc(s.family['rumorSend']!)}</button>
        </details>
      </section>
      <section class="card" id="ideasCard">
        <h2>${esc(s.family['ideas']!)}</h2>
        <div id="ideas" class="list"></div>
      </section>
      <section class="card" id="chatCard">
        <h2>${esc(s.family['chat']!)}</h2>
        <div id="chat" class="chat" aria-live="polite"></div>
        <form id="chatForm" class="row">
          <input id="msg" maxlength="200" autocomplete="off" placeholder="${esc(s.family['chatHint']!)}">
          <button type="submit">${esc(s.family['send']!)}</button>
        </form>
      </section>
      <section class="card stack">
        <h2>${esc(s.family['families']!)}</h2>
        <div id="families" class="list"></div>
        <h2>${esc(s.family['names']!)}</h2>
        <div id="names" class="chips"></div>
        <div id="events" class="list"></div>
      </section>
    </div>
    <script>var FAMILY_STRINGS = $strings, HOST = $host;</script>
    <script>$browserSoundsJs</script>
    <script>$_script</script>''';
}

/// Extra styles for the family page, added to the join page's own.
const familyCss = '''
[hidden]{display:none!important}
.fam h2{margin:0 0 10px;font-size:15px}
.card{background:var(--card);border:1px solid var(--line);border-radius:20px;padding:16px}
.banner{padding:14px 16px;border-radius:18px;background:var(--card);border:1px solid var(--line);font-weight:800;font-size:18px;text-align:center}
.banner.mine{background:var(--primary);color:var(--on-primary);border-color:var(--primary)}
.banner.won{background:var(--good);color:#fff;border-color:var(--good)}
.chips{display:flex;flex-wrap:wrap;gap:8px}
.chip{padding:6px 12px;border-radius:99px;background:var(--bg);border:1px solid var(--line);font-weight:700;font-size:14px}
.chip.head{border-color:var(--primary)}
.chip.slip{background:var(--slip);color:var(--slip-ink);border-color:var(--slip-edge);border-radius:6px}
.chip.done{opacity:.55}
img.ink{height:30px;max-width:100%;vertical-align:middle;margin-inline-end:4px}
.idea img.ink{display:block;height:36px}
select{width:100%;height:50px;border-radius:14px;border:1.5px solid var(--line);background:var(--card);color:var(--ink);font:inherit;font-size:16px;padding:0 12px}
.list{display:flex;flex-direction:column;gap:8px}
.idea{display:flex;align-items:center;gap:8px;padding:10px 12px;border-radius:14px;background:var(--bg)}
.idea span{flex:1;font-weight:700}
.idea button,.row button{height:40px;padding:0 14px;font-size:14px;border-radius:12px}
.idea button.ghostb{background:transparent;color:var(--primary);border:1.5px solid var(--primary)}
.chat{display:flex;flex-direction:column;gap:6px;max-height:260px;overflow:auto;margin-bottom:10px}
.msg{padding:8px 12px;border-radius:14px;background:var(--bg);font-size:15px}
.msg b{display:block;font-size:12px;color:var(--muted)}
.msg.me{background:color-mix(in srgb,var(--primary) 16%,var(--card))}
.row{display:flex;gap:8px}
.row input{flex:1;height:44px}
.event{margin:0;font-size:14px;color:var(--muted)}
.event.ok{color:var(--good);font-weight:700}
.fam-line{font-size:14px}
.fam-line b{font-size:15px}
.net{position:sticky;top:8px;z-index:5;padding:12px 14px;border-radius:14px;background:#B3261E;color:#fff;font-weight:800;text-align:center}
.net.ok{background:var(--good)}
.net.over{background:var(--card);color:var(--ink);border:1px solid var(--line)}
.chip.away,.away{opacity:.6}
.chip.away{border-style:dashed}
.chip.pick{cursor:pointer;background:var(--card);border-color:var(--primary);color:var(--primary);font-size:16px;padding:10px 16px}
.msg.pending{opacity:.6}
.msg.pending i{display:block;font-size:12px}
button:disabled{opacity:.5}
.soundb{align-self:flex-end;height:36px;padding:0 12px;font-size:13px;border-radius:99px;background:transparent;color:var(--muted);border:1px solid var(--line)}
.twist{border:2px solid var(--primary)}
.wanted{border:2px solid #B3261E}
.wanted h2{color:#B3261E}
.chip.wantedslip{border:2px solid #B3261E}
.rumor{margin:0;padding:10px 12px;border-radius:14px;background:var(--bg);font-weight:700}
.rumor.new{outline:2px solid var(--primary)}
.event.secret{font-style:italic}
.event.tag b{color:var(--primary)}
summary{cursor:pointer;font-weight:800;color:var(--primary);padding:6px 0}
details .field,details .help,details button{margin-top:10px}
#pendBtns button{flex:1}
''';

const _script = r'''
(function(){
  var S = FAMILY_STRINGS, st = null, lastV = '', wasMyTurn = false;
  var fails = 0, offline = false, okTimer = null, outbox = [], sending = false, loading = false, loadAgain = false;
  var overShown = false;
  function $(id){ return document.getElementById(id); }
  // Each inserted name is isolated, so an English name inside an Arabic sentence (or the reverse) keeps the word order.
  function t(key, vars){ var s = S[key] || key; for (var k in vars) s = s.split('{' + k + '}').join(iso(vars[k])); return s; }
  function iso(text){ return '\u2068' + text + '\u2069'; }
  function el(tag, cls, text){ var e = document.createElement(tag); if (cls) e.className = cls; if (text != null) e.textContent = text; return e; }
  function nameOf(id){ for (var i = 0; i < st.players.length; i++) if (st.players[i].id === id) return st.players[i].name; return ''; }
  function slipOf(id){ for (var i = 0; i < st.slips.length; i++) if (st.slips[i].id === id) return st.slips[i]; return null; }
  // A handwritten name reads as a numbered ✍️ in text, and shows as its drawing where there is room.
  function slipText(x){ return x.ink ? '\u270D\uFE0F' + (x.id + 1) : x.text; }
  function inkImg(x){ var i = el('img', 'ink'); i.src = '/ink/' + x.id + '.png'; i.alt = slipText(x); return i; }
  var lastRumor = null, lastAsks = null;
  var sfx = window.sfx || { drumroll: function(){}, joy: function(){}, wrong: function(){}, muted: true, setMuted: function(){} };
  function soundLabel(){ $('sound').textContent = sfx.muted ? S.soundOff : S.soundOn; }
  $('sound').onclick = function(){ sfx.setMuted(!sfx.muted); soundLabel(); };
  soundLabel();

  // A zaghrouta when a family grows, a sad trombone for a miss. Only the phones
  // of the families in the ask play it, so the table doesn't hear a chorus.
  function sounds(){
    var had = lastAsks;
    lastAsks = st.asks;
    if (had === null || st.asks <= had || !st.events.length || !st.myHead) return;
    var e = st.events[0];
    if (e.hidden || e.blocked) return;
    var mine = st.players.some(function(p){ return p.head === st.myHead && (p.id === e.asker || p.id === e.target); });
    if (!mine) return;
    if (e.correct) sfx.joy(); else sfx.wrong();
  }

  function clear(e){ while (e.firstChild) e.removeChild(e.firstChild); }
  function show(e, on){ e.hidden = !on; }

  function fill(select, items){
    var keep = select.value;
    clear(select);
    select.appendChild(el('option', '', '—')).value = '';
    items.forEach(function(it){ var o = el('option', '', it.label); o.value = it.value; select.appendChild(o); });
    select.value = keep;
    if (select.value !== keep) select.value = '';
  }

  // A dead Wi-Fi can leave a request hanging for a minute; give up after a few seconds instead.
  function send(path, opts){
    var ctl = window.AbortController ? new AbortController() : null, timer = null;
    if (ctl) { opts.signal = ctl.signal; timer = setTimeout(function(){ ctl.abort(); }, 4000); }
    return fetch(path, opts).then(function(r){ clearTimeout(timer); connected(true); return r; },
      function(e){ clearTimeout(timer); connected(false); throw e; });
  }

  function connected(ok){
    var net = $('net');
    if (ok) {
      fails = 0;
      if (overShown) { overShown = false; show(net, false); }
      if (!offline) return;
      offline = false;
      net.className = 'net ok'; net.textContent = S.backOnline; show(net, true);
      clearTimeout(okTimer); okTimer = setTimeout(function(){ show(net, false); }, 2500);
      controls(); flush();
      return;
    }
    fails++;
    if (fails < 2) return;
    // Once there is a winner, the host closing the room is the expected end, not a lost connection.
    if (st && st.winner) {
      overShown = true;
      clearTimeout(okTimer);
      net.className = 'net over'; net.textContent = S.gameOverBye; show(net, true);
      return;
    }
    offline = true;
    clearTimeout(okTimer);
    net.className = 'net';
    net.textContent = fails >= 8 ? t('stillOffline', { host: HOST }) : S.reconnecting;
    show(net, true);
    controls();
  }

  // While offline, a guess can't be sent, so it can't be lost or sent twice.
  function controls(){
    var busy = !!(st && st.pending);
    $('go').disabled = offline || (busy && $('go').dataset.action === 'guess');
    $('rumorGo').disabled = offline;
    var b = $('pendBtns').getElementsByTagName('button');
    for (var i = 0; i < b.length; i++) b[i].disabled = offline;
  }

  function post(path, data, err){
    var body = new URLSearchParams(data);
    err = err || $('err');
    return send(path, { method: 'POST', body: body, headers: { 'Content-Type': 'application/x-www-form-urlencoded' } })
      // The phone did answer, so an empty or garbled reply is an error, not a lost connection.
      .then(function(r){ return r.text().then(function(text){
        try { var res = JSON.parse(text); if (res && typeof res === 'object') return res; } catch (e) {}
        return { error: r.ok ? null : 'generic' };
      }); })
      .then(function(res){
        if (res.error) { err.textContent = S['err_' + res.error] || S.err_generic; show(err, true); }
        else show(err, false);
        load();
        return res;
      }, function(){ err.textContent = S.err_offline; show(err, true); return null; });
  }

  // Messages typed while offline wait here, in order, and go out once the phone is back.
  // Each carries its own id, so a resend of one that did arrive isn't posted twice.
  function flush(){
    if (sending || offline || !outbox.length) return;
    sending = true;
    send('/game/say', { method: 'POST', body: new URLSearchParams({ text: outbox[0].text, cid: outbox[0].cid }), headers: { 'Content-Type': 'application/x-www-form-urlencoded' } })
      .then(function(){ outbox.shift(); sending = false; load(); flush(); }, function(){ sending = false; renderChat(); });
  }

  function renderChat(){
    if (!st || !st.me || !st.chatOn) return;
    var chat = $('chat'), atBottom = chat.scrollHeight - chat.scrollTop - chat.clientHeight < 40;
    clear(chat);
    // Each message reads in its own direction, whatever the page's.
    function bubble(cls, author, text){ var b = el('div', cls); b.appendChild(el('b', '', author)).dir = 'auto'; b.appendChild(el('div', '', text)).dir = 'auto'; chat.appendChild(b); return b; }
    st.chat.forEach(function(m){ bubble('msg' + (m.author === st.me ? ' me' : ''), nameOf(m.author), m.text); });
    outbox.forEach(function(m){ bubble('msg me pending', nameOf(st.me), m.text).appendChild(el('i', '', S.sending)); });
    if (atBottom) chat.scrollTop = chat.scrollHeight;
  }

  function isAway(id){ return st.away.indexOf(id) >= 0; }
  function familyAway(head){ var any = false, all = true; st.players.forEach(function(p){ if (p.head === head) { any = true; if (!isAway(p.id)) all = false; } }); return any && all; }
  function nameTag(id){ return iso(nameOf(id)) + (isAway(id) ? ' · ' + S.offline : ''); }

  function renderClaim(){
    var card = $('claimCard'), mine = st.myClaim;
    var open = !st.me && !st.winner && (st.claimable.length > 0 || !!mine);
    show(card, open);
    if (!open) return;
    var list = $('claimList'), err = $('claimErr'); clear(list);
    if (mine && mine.status === 'pending') {
      show(err, false);
      $('claimTitle').textContent = t('claimPending', { host: HOST, name: nameOf(mine.player) });
      show($('claimHelp'), false);
      return;
    }
    $('claimTitle').textContent = mine && mine.status === 'denied' ? t('claimDenied', { host: HOST }) : S.claimTitle;
    $('claimHelp').textContent = t('claimHelp', { host: HOST });
    show($('claimHelp'), st.claimable.length > 0);
    st.claimable.forEach(function(p){
      var b = el('button', 'chip pick', p.name);
      b.type = 'button';
      b.onclick = function(){ post('/game/claim', { player: p.id }, err); };
      list.appendChild(b);
    });
  }

  function slipName(id){ var x = slipOf(id); return x ? slipText(x) : ''; }

  function pendTitle(pend){
    var asker = nameOf(pend.asker);
    return pend.kind === 'letMeGo' ? t('letMeGoAsked', { asker: asker, name: slipName(pend.slip) })
      : t(pend.kind + 'Title', { asker: asker });
  }

  // Someone asked this phone, caught it or wrongly accused it: it answers here.
  function renderPending(pend){
    var card = $('pendCard'), mine = !!(pend && pend.mine && st.me);
    show(card, mine);
    if (!mine) { card.dataset.key = ''; return; }
    // Redrawing on every poll would drop what the person is picking.
    var key = pend.kind + ':' + pend.asker + ':' + pend.slip;
    if (card.dataset.key === key) { controls(); return; }
    card.dataset.key = key;
    sfx.drumroll();
    try { navigator.vibrate && navigator.vibrate([200, 100, 200]); } catch (e) {}
    var err = $('pendErr'), btns = $('pendBtns'), slips = $('pendSlips'), who = $('pendWho');
    who.value = '';
    clear(btns); clear(slips); show(err, false);
    var asker = nameOf(pend.asker), picked = null;
    function button(label, cls, onclick){ var b = el('button', cls, label); b.type = 'button'; b.onclick = onclick; btns.appendChild(b); return b; }
    function pickSlips(){
      (pend.slips || []).forEach(function(id){
        var c = el('button', 'chip pick', slipName(id)); c.type = 'button';
        var x = slipOf(id); if (x && x.ink) c.insertBefore(inkImg(x), c.firstChild);
        c.onclick = function(){ picked = id; var all = slips.children; for (var i = 0; i < all.length; i++) all[i].className = 'chip pick'; c.className = 'chip slip'; };
        slips.appendChild(c);
      });
    }
    show($('pendWhoF'), pend.kind === 'counter');
    $('pendTitle').textContent = pendTitle(pend);
    if (pend.kind === 'letMeGo') {
      $('pendHelp').textContent = S.letMeGoHint;
      button(S.letMeGoUse, '', function(){ post('/game/letmego', { use: '1' }, err); });
      button(S.letMeGoAnswer, 'ghostb', function(){ post('/game/letmego', { use: '0' }, err); });
    } else if (pend.kind === 'counter') {
      $('pendHelp').textContent = S.counterHint;
      fill(who, (pend.targets || []).map(function(id){ return { value: id, label: nameOf(id) }; }));
      pickSlips();
      button(S.counterShoot, '', function(){
        if (!who.value || picked == null) { err.textContent = S.err_pickBoth; show(err, true); return; }
        post('/game/counter', { target: who.value, slip: picked }, err);
      });
      button(S.pass, 'ghostb', function(){ post('/game/passcounter', {}, err); });
    } else {
      $('pendHelp').textContent = t('revengeHint', { asker: asker });
      pickSlips();
      button(S.revengeTake, '', function(){
        if (picked == null) { err.textContent = S.err_pickBoth; show(err, true); return; }
        post('/game/revenge', { slip: picked }, err);
      });
      button(S.pass, 'ghostb', function(){ post('/game/passrevenge', {}, err); });
    }
  }

  function renderWanted(){
    var x = st.wanted == null ? null : slipOf(st.wanted), open = !!x && !x.writer && !st.winner;
    show($('wantedCard'), open || st.bonus > 0);
    $('wantedTitle').textContent = open ? t('wantedTitle', { name: slipText(x) }) : '';
    $('wantedHelp').textContent = (open ? S.wantedDetail : '') + (st.bonus > 0 ? (open ? ' ' : '') + t('bonus', { count: st.bonus }) : '');
  }

  function renderRumors(){
    var on = st.twists.rumors;
    show($('rumorCard'), on && (st.rumors.length > 0 || st.canRumor));
    if (!on) return;
    var list = $('rumorList'); clear(list);
    var top = st.rumors.length ? st.rumors[0].id : -1;
    // A rumor that lands while the page is open stands out, and the phone buzzes once.
    var fresh = lastRumor !== null && top > lastRumor;
    st.rumors.forEach(function(r){ list.appendChild(el('p', 'rumor' + (fresh && r.id === top ? ' new' : ''), t('rumorLine', { target: nameOf(r.target), name: slipName(r.slip) }))); });
    if (fresh) { try { navigator.vibrate && navigator.vibrate(60); } catch (e) {} }
    if (lastRumor === null || top > lastRumor) lastRumor = top;
    show($('rumorForm'), st.canRumor && !!st.me);
    fill($('rumorWho'), st.players.filter(function(p){ return p.id !== st.me; }).map(function(p){ return { value: p.id, label: p.name }; }));
    fill($('rumorWhich'), st.slips.filter(function(x){ return !x.writer; }).map(function(x){ return { value: String(x.id), label: slipText(x) }; }));
  }

  function render(){
    var me = st.me, mine = st.myHead, won = st.winner;
    var pend = won ? null : st.pending;
    // With secret catches, turns go round every player, so "your turn" is yours alone.
    var myTurn = !won && mine && (st.secret ? st.turnPlayer === me : st.turn === mine);
    var banner = $('banner');
    banner.className = 'banner' + (won ? ' won' : (myTurn && !pend) || (pend && pend.mine) ? ' mine' : '');
    banner.textContent = won
      ? (mine === won ? S.youWin : t('familyWins', { name: nameOf(won) }))
      : pend
        ? (pend.mine ? pendTitle(pend)
            : pend.responder ? t('waiting', { name: nameOf(pend.responder) }) : S.waitingSomeone)
      : st.secret
        ? (myTurn ? S.youAsk : isAway(st.turnPlayer) ? t('familyAway', { name: nameOf(st.turnPlayer), host: HOST }) : t('playerAsks', { name: nameOf(st.turnPlayer) }))
      : myTurn
        ? (st.canAsk && me !== mine
            ? t('actingHead', { name: nameOf(mine) })
            : S.turnYours + ' ' + (me === mine ? S.youDecide : t('headDecides', { name: nameOf(mine) })))
        : familyAway(st.turn)
          ? t('familyAway', { name: nameOf(st.turn), host: HOST })
          : t('turnOther', { name: nameOf(st.turn) });
    renderClaim();
    renderPending(pend);
    var awards = $('awards'); clear(awards);
    show($('awardsCard'), !!won && st.awards.length > 0);
    st.awards.forEach(function(a){
      var row = el('div', 'idea');
      row.appendChild(el('span', '', S['award_' + a.kind] || a.kind));
      row.appendChild(el('b', '', nameOf(a.player))).dir = 'auto';
      awards.appendChild(row);
    });
    sounds();
    renderWanted();
    renderRumors();
    if (myTurn && !wasMyTurn) { try { navigator.vibrate && navigator.vibrate([120, 80, 120]); } catch (e) {} }
    wasMyTurn = !!myTurn;

    show($('mineCard'), !!me);
    show($('actCard'), !!me && !won);
    show($('ideasCard'), !!me && !won);
    show($('chatCard'), !!me && st.chatOn);
    if (me) {
      $('mineTitle').textContent = me === mine ? S.yourFamily : t('familyOf', { name: nameOf(mine) });
      var box = $('mine'); clear(box);
      st.players.forEach(function(p){ if (p.head === mine) box.appendChild(el('span', 'chip' + (p.id === mine ? ' head' : '') + (isAway(p.id) ? ' away' : ''), (p.id === mine ? '👑 ' : '') + iso(p.name) + (p.id === me ? ' ' + S.youTag : '') + (isAway(p.id) ? ' · ' + S.offline : ''))); });

      // The host works out who can be asked and which names are still open to this family.
      fill($('who'), st.askable.map(function(id){ return { value: id, label: nameOf(id) }; }));
      fill($('which'), st.open.map(function(id){ return { value: String(id), label: slipName(id) }; }));
      var line = $('cardLine');
      show(line, st.twists.letMeGo && !won);
      line.textContent = st.card ? S.cardReady : S.cardUsed;
      var go = $('go');
      go.textContent = st.canAsk ? S.ask : S.suggest;
      go.dataset.action = st.canAsk ? 'guess' : 'suggest';
      controls();

      var ideas = $('ideas'); clear(ideas);
      if (!st.ideas.length) ideas.appendChild(el('p', 'help', S.noIdeas));
      st.ideas.forEach(function(idea){
        var row = el('div', 'idea');
        var slip = slipOf(idea.slip);
        var ideaText = row.appendChild(el('span', '', t('ideaText', { name: nameOf(idea.target), slip: slip ? slipText(slip) : '' })));
        if (slip && slip.ink) ideaText.appendChild(inkImg(slip));
        row.appendChild(el('small', '', t('votes', { count: idea.votes })));
        var vote = el('button', idea.mine ? 'ghostb' : '', idea.mine ? S.voted : S.vote);
        vote.type = 'button';
        vote.onclick = function(){ post(idea.mine ? '/game/unvote' : '/game/suggest', { target: idea.target, slip: idea.slip }); };
        row.appendChild(vote);
        if (st.canAsk) {
          var use = el('button', '', S.use);
          use.type = 'button';
          use.onclick = function(){ $('who').value = idea.target; $('which').value = String(idea.slip); window.scrollTo({ top: $('actCard').offsetTop - 12, behavior: 'smooth' }); };
          row.appendChild(use);
        }
        ideas.appendChild(row);
      });

      renderChat();
    }

    var fams = $('families'); clear(fams);
    st.families.forEach(function(f){
      var line = el('div', 'fam-line');
      line.appendChild(el('b', '', (f.head === st.turn && !won ? '▶ ' : '') + t('familyOf', { name: nameOf(f.head) }) + ' '));
      line.appendChild(document.createTextNode(f.members.map(nameTag).join(S.sep)));
      fams.appendChild(line);
    });
    var names = $('names'); clear(names);
    st.slips.forEach(function(x){
      var chip = names.appendChild(el('span', 'chip slip' + (x.writer ? ' done' : '') + (x.id === st.wanted && !x.writer ? ' wantedslip' : ''), iso(slipText(x)) + (x.writer ? ' · ' + iso(nameOf(x.writer)) : '')));
      if (x.ink) chip.insertBefore(inkImg(x), chip.firstChild);
    });
    var events = $('events'); clear(events);
    st.events.forEach(function(e){
      var vars = { asker: nameOf(e.asker), target: nameOf(e.target), slip: slipName(e.slip) };
      if (e.hidden) { events.appendChild(el('p', 'event secret', t('eventSecret', vars))); return; }
      var p = el('p', 'event' + (e.correct && !e.blocked ? ' ok' : '') + (e.kind !== 'ask' ? ' tag' : ''));
      if (e.kind === 'counter' || e.kind === 'revenge') p.appendChild(el('b', '', (e.kind === 'counter' ? S.tagCounter : S.tagRevenge) + ' '));
      p.appendChild(document.createTextNode(e.blocked ? t('eventBlocked', vars) : t(e.correct ? 'eventCorrect' : 'eventWrong', vars)));
      if (e.wanted) p.appendChild(document.createTextNode(' ' + S.tagWanted));
      events.appendChild(p);
    });
  }

  // One call at a time, so a slow answer can't land after a newer one and draw an older game.
  function load(){
    if (loading) { loadAgain = true; return; }
    loading = true; loadAgain = false;
    send('/game', { cache: 'no-store' }).then(function(r){
      // No game any more: the host went back to the room or started a new round.
      if (r.status === 404) { location.replace('/'); return null; }
      return r.ok ? r.json() : null;
    }).then(function(s){
      if (!s) return;
      // Answers arrive in order, so an older version means the host started a new game.
      if (st && s.v < st.v) { location.replace('/'); return; }
      st = s;
      // The claim status is per phone, so it redraws the page too.
      var v = s.v + ':' + (s.me || '') + ':' + (s.myClaim ? s.myClaim.status : '');
      if (v !== lastV) { lastV = v; render(); }
      // Reachable again: send what's waiting, even if the drop was too short to show as offline.
      flush();
    }).catch(function(){}).then(function(){
      loading = false;
      if (loadAgain) load();
    });
  }

  $('go').onclick = function(){
    var who = $('who').value, which = $('which').value, err = $('err');
    if (!who || !which) { err.textContent = S.err_pickBoth; show(err, true); return; }
    post('/game/' + this.dataset.action, { target: who, slip: which }).then(function(res){
      if (res && !res.error) { $('who').value = ''; $('which').value = ''; }
    });
  };
  $('rumorGo').onclick = function(){
    var who = $('rumorWho').value, which = $('rumorWhich').value, err = $('rumorErr');
    if (!who || !which) { err.textContent = S.err_pickBoth; show(err, true); return; }
    post('/game/rumor', { target: who, slip: which }, err).then(function(res){ if (res && !res.error) $('rumorForm').open = false; });
  };
  $('chatForm').onsubmit = function(ev){
    ev.preventDefault();
    var input = $('msg'), text = input.value.trim();
    if (!text) return;
    input.value = '';
    outbox.push({ text: text, cid: Date.now().toString(36) + Math.random().toString(36).slice(2, 10) });
    renderChat();
    flush();
  };
  // Back from the lock screen or another app: catch up at once instead of on the next tick.
  document.addEventListener('visibilitychange', function(){ if (!document.hidden) load(); });
  load();
  setInterval(load, 1500);
})();
''';
