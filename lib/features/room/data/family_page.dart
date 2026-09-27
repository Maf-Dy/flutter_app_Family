import 'dart:convert';

import 'join_strings.dart';

/// The body of a friend's page while a family game runs: their family, the
/// guess or idea pickers, family ideas and chat, and the public board.
///
/// Static markup with ids; the script fills it from `/game` every 1.5 s, and
/// only ever writes user text with `textContent`, never as HTML.
String familyBody(JoinStrings s, String Function(String) esc) {
  final strings = jsonEncode(s.family).replaceAll('</', r'<\/');
  return '''
    <div class="stack fam">
      <div id="banner" class="banner" role="status" aria-live="polite"></div>
      <section class="card" id="mineCard">
        <h2 id="mineTitle"></h2>
        <div id="mine" class="chips"></div>
      </section>
      <section class="card stack" id="actCard">
        <div class="field"><label for="who">${esc(s.family['who']!)}</label><select id="who"></select></div>
        <div class="field"><label for="which">${esc(s.family['which']!)}</label><select id="which"></select></div>
        <p id="err" class="error" hidden></p>
        <button id="go" type="button"></button>
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
    <script>var FAMILY_STRINGS = $strings;</script>
    <script>$_script</script>''';
}

/// Extra styles for the family page, added to the join page's own.
const familyCss = '''
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
.event{font-size:14px;color:var(--muted)}
.event.ok{color:var(--good);font-weight:700}
.fam-line{font-size:14px}
.fam-line b{font-size:15px}
''';

const _script = r'''
(function(){
  var S = FAMILY_STRINGS, st = null, lastV = -1, wasMyTurn = false;
  function $(id){ return document.getElementById(id); }
  function t(key, vars){ var s = S[key] || key; for (var k in vars) s = s.split('{' + k + '}').join(vars[k]); return s; }
  function el(tag, cls, text){ var e = document.createElement(tag); if (cls) e.className = cls; if (text != null) e.textContent = text; return e; }
  function nameOf(id){ for (var i = 0; i < st.players.length; i++) if (st.players[i].id === id) return st.players[i].name; return ''; }
  function slipOf(id){ for (var i = 0; i < st.slips.length; i++) if (st.slips[i].id === id) return st.slips[i]; return null; }
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

  function post(path, data){
    var body = new URLSearchParams(data);
    return fetch(path, { method: 'POST', body: body, headers: { 'Content-Type': 'application/x-www-form-urlencoded' } })
      .then(function(r){ return r.json(); })
      .then(function(res){
        var err = $('err');
        if (res.error) { err.textContent = S['err_' + res.error] || S.err_generic; show(err, true); }
        else show(err, false);
        load();
        return res;
      })
      .catch(function(){});
  }

  function render(){
    var me = st.me, mine = st.myHead, won = st.winner;
    var myTurn = !won && mine && st.turn === mine;
    var banner = $('banner');
    banner.className = 'banner' + (won ? ' won' : myTurn ? ' mine' : '');
    banner.textContent = won
      ? (mine === won ? S.youWin : t('familyWins', { name: nameOf(won) }))
      : myTurn
        ? S.turnYours + ' ' + (me === mine ? S.youDecide : t('headDecides', { name: nameOf(mine) }))
        : t('turnOther', { name: nameOf(st.turn) });
    if (myTurn && !wasMyTurn) { try { navigator.vibrate && navigator.vibrate([120, 80, 120]); } catch (e) {} }
    wasMyTurn = !!myTurn;

    show($('mineCard'), !!me);
    show($('actCard'), !!me && !won);
    show($('ideasCard'), !!me && !won);
    show($('chatCard'), !!me && st.chatOn);
    if (me) {
      $('mineTitle').textContent = me === mine ? S.yourFamily : t('familyOf', { name: nameOf(mine) });
      var box = $('mine'); clear(box);
      st.players.forEach(function(p){ if (p.head === mine) box.appendChild(el('span', 'chip' + (p.id === mine ? ' head' : ''), (p.id === mine ? '👑 ' : '') + p.name + (p.id === me ? ' ' + S.youTag : ''))); });

      fill($('who'), st.players.filter(function(p){ return p.head !== mine; }).map(function(p){ return { value: p.id, label: p.name }; }));
      fill($('which'), st.slips.filter(function(x){ return x.writer == null; }).map(function(x){ return { value: String(x.id), label: x.text }; }));
      var go = $('go');
      go.textContent = me === mine && myTurn ? S.ask : S.suggest;
      go.dataset.action = me === mine && myTurn ? 'guess' : 'suggest';

      var ideas = $('ideas'); clear(ideas);
      if (!st.ideas.length) ideas.appendChild(el('p', 'help', S.noIdeas));
      st.ideas.forEach(function(idea){
        var row = el('div', 'idea');
        var slip = slipOf(idea.slip);
        row.appendChild(el('span', '', t('ideaText', { name: nameOf(idea.target), slip: slip ? slip.text : '' })));
        row.appendChild(el('small', '', t('votes', { count: idea.votes })));
        var vote = el('button', idea.mine ? 'ghostb' : '', idea.mine ? S.voted : S.vote);
        vote.type = 'button';
        vote.onclick = function(){ post(idea.mine ? '/game/unvote' : '/game/suggest', { target: idea.target, slip: idea.slip }); };
        row.appendChild(vote);
        if (me === mine && myTurn) {
          var use = el('button', '', S.use);
          use.type = 'button';
          use.onclick = function(){ $('who').value = idea.target; $('which').value = String(idea.slip); window.scrollTo({ top: $('actCard').offsetTop - 12, behavior: 'smooth' }); };
          row.appendChild(use);
        }
        ideas.appendChild(row);
      });

      if (st.chatOn) {
        var chat = $('chat'), atBottom = chat.scrollHeight - chat.scrollTop - chat.clientHeight < 40;
        clear(chat);
        st.chat.forEach(function(m){ var b = el('div', 'msg' + (m.author === me ? ' me' : '')); b.appendChild(el('b', '', nameOf(m.author))); b.appendChild(document.createTextNode(m.text)); chat.appendChild(b); });
        if (atBottom) chat.scrollTop = chat.scrollHeight;
      }
    }

    var fams = $('families'); clear(fams);
    st.families.forEach(function(f){
      var line = el('div', 'fam-line');
      line.appendChild(el('b', '', (f.head === st.turn && !won ? '▶ ' : '') + t('familyOf', { name: nameOf(f.head) }) + ' '));
      line.appendChild(document.createTextNode(f.members.map(nameOf).join(S.sep)));
      fams.appendChild(line);
    });
    var names = $('names'); clear(names);
    st.slips.forEach(function(x){ names.appendChild(el('span', 'chip slip' + (x.writer ? ' done' : ''), x.text + (x.writer ? ' · ' + nameOf(x.writer) : ''))); });
    var events = $('events'); clear(events);
    st.events.forEach(function(e){
      var slip = slipOf(e.slip), vars = { asker: nameOf(e.asker), target: nameOf(e.target), slip: slip ? slip.text : '' };
      events.appendChild(el('p', 'event' + (e.correct ? ' ok' : ''), t(e.correct ? 'eventCorrect' : 'eventWrong', vars)));
    });
  }

  function load(){
    return fetch('/game', { cache: 'no-store' }).then(function(r){ return r.ok ? r.json() : null; }).then(function(s){
      if (!s) return;
      st = s;
      if (s.v !== lastV) { lastV = s.v; render(); }
    }).catch(function(){});
  }

  $('go').onclick = function(){
    var who = $('who').value, which = $('which').value, err = $('err');
    if (!who || !which) { err.textContent = S.err_pickBoth; show(err, true); return; }
    post('/game/' + this.dataset.action, { target: who, slip: which }).then(function(res){
      if (res && !res.error) { $('who').value = ''; $('which').value = ''; }
    });
  };
  $('chatForm').onsubmit = function(ev){
    ev.preventDefault();
    var input = $('msg'), text = input.value.trim();
    if (!text) return;
    input.value = '';
    post('/game/say', { text: text });
  };
  load();
  setInterval(load, 1500);
})();
''';
