'use strict';

// Browser side of backup and restore (handoff 0005). Flutter calls these
// through dart:js_interop (lib/services/backup_service_web.dart).
(function () {
  function download(filename, text) {
    const blob = new Blob([text], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    // Give the browser a moment to start the download before revoking.
    setTimeout(() => URL.revokeObjectURL(url), 10000);
  }

  // Resolves with the file's text, or null when the picker is cancelled.
  function pickFile() {
    return new Promise((resolve, reject) => {
      const input = document.createElement('input');
      input.type = 'file';
      input.accept = '.json,application/json';
      input.style.display = 'none';
      let settled = false;
      const done = (value) => {
        if (settled) return;
        settled = true;
        input.remove();
        resolve(value);
      };
      input.addEventListener('change', () => {
        const file = input.files && input.files[0];
        if (!file) return done(null);
        file.text().then(done, reject);
      });
      // Modern browsers fire 'cancel'; older ones only refocus the window.
      input.addEventListener('cancel', () => done(null));
      window.addEventListener('focus', () => setTimeout(() => done(null), 1000), { once: true });
      document.body.appendChild(input);
      input.click();
    });
  }

  // Asks the browser not to evict our site data under storage pressure.
  async function persist() {
    try {
      if (navigator.storage && navigator.storage.persist) {
        return await navigator.storage.persist();
      }
    } catch (_) {
      // Ignore: persistence is best effort.
    }
    return false;
  }

  window.dqBackup = { download, pickFile, persist };

  // Once per load, best effort (ADR 0014).
  persist();
})();
