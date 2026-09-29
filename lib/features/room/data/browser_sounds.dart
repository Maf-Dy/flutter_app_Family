/// Sound effects for friends' browsers: defines `window.sfx`.
///
/// Plays the same WAVs as the app, fetched once from [LanRoomHost] at
/// `/sounds/<file>.wav` and decoded with WebAudio. Browsers only allow sound
/// after the person has touched the page, so the audio unlocks on their first
/// tap; until then, and whenever anything fails, the calls simply do nothing.
///
/// To use it, put it in a page's script, before code that calls it:
///
/// ```dart
/// '<script>$browserSoundsJs</script>'
/// ```
///
/// then call `sfx.drumroll()`, `sfx.joy()` or `sfx.wrong()`. A mute switch can
/// read `sfx.muted` and call `sfx.setMuted(true | false)`; the choice is kept in
/// the browser's localStorage. `sfx.stop()` cuts off anything playing.
library;

// Raw, so nothing in the script is taken as Dart interpolation. It never contains "</script".
const browserSoundsJs = r'''
(function () {
  var KEY = 'family.sfxMuted';
  var FILES = {drumroll: '/sounds/drumroll.wav', joy: '/sounds/zaghrouta.wav', wrong: '/sounds/trombone.wav'};
  var TAPS = ['pointerdown', 'touchend', 'mousedown', 'keydown'];
  var Ctx = window.AudioContext || window.webkitAudioContext;
  var ctx = null, loading = null, buffers = {}, playing = {};
  var muted = false;
  try { muted = window.localStorage.getItem(KEY) === '1'; } catch (e) {}

  function context() {
    if (!ctx && Ctx) { try { ctx = new Ctx(); } catch (e) { ctx = null; } }
    return ctx;
  }

  // Older Safari only has the callback form of decodeAudioData.
  function decode(c, data) {
    return new Promise(function (ok, fail) {
      try {
        var p = c.decodeAudioData(data, ok, fail);
        if (p && p.then) p.then(ok, fail);
      } catch (e) { fail(e); }
    });
  }

  function load() {
    if (loading) return loading;
    var c = context();
    if (!c || !window.fetch || !window.Promise) return (loading = Promise.resolve());
    loading = Promise.all(Object.keys(FILES).map(function (name) {
      return fetch(FILES[name])
        .then(function (r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.arrayBuffer(); })
        .then(function (data) { return decode(c, data); })
        .then(function (buffer) { buffers[name] = buffer; })
        .catch(function () {});
    }));
    return loading;
  }

  function stopListening() {
    TAPS.forEach(function (t) { document.removeEventListener(t, unlock, true); });
  }

  // Runs inside the first tap: resumes the audio and plays a silent sample, which iOS needs.
  function unlock() {
    var c = context();
    if (!c) { stopListening(); return; }
    try {
      var s = c.createBufferSource();
      s.buffer = c.createBuffer(1, 1, 22050);
      s.connect(c.destination);
      s.start(0);
    } catch (e) {}
    try {
      var resumed = c.state === 'suspended' ? c.resume() : null;
      if (resumed && resumed.then) {
        resumed.then(function () { if (c.state === 'running') stopListening(); }, function () {});
      } else if (c.state === 'running') {
        stopListening();
      }
    } catch (e) {}
    load();
  }
  TAPS.forEach(function (t) { document.addEventListener(t, unlock, true); });

  function stop(name) {
    var s = playing[name];
    playing[name] = null;
    if (s) { try { s.stop(); } catch (e) {} }
  }

  function stopAll() { Object.keys(FILES).forEach(stop); }

  function play(name) {
    if (muted) return;
    try {
      var c = context();
      if (!c) return;
      load().then(function () {
        var buffer = buffers[name];
        // Still locked: skip it rather than have it play late, on the next tap.
        if (!buffer || muted || c.state !== 'running') return;
        stop(name);
        var s = c.createBufferSource();
        s.buffer = buffer;
        s.connect(c.destination);
        s.onended = function () { if (playing[name] === s) playing[name] = null; };
        playing[name] = s;
        s.start(0);
      }).catch(function () {});
    } catch (e) {}
  }

  window.sfx = {
    drumroll: function () { play('drumroll'); },
    joy: function () { stop('drumroll'); play('joy'); },
    wrong: function () { stop('drumroll'); play('wrong'); },
    stop: stopAll,
    setMuted: function (on) {
      muted = !!on;
      try { window.localStorage.setItem(KEY, muted ? '1' : '0'); } catch (e) {}
      if (muted) stopAll();
    },
    get muted() { return muted; }
  };
})();
''';
