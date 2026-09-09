(function () {
  if (location.hostname !== 'nesd.jpj.dev') {
    return;
  }

  var key = 'nesd-counted:' + location.pathname;

  try {
    if (sessionStorage.getItem(key)) {
      return;
    }

    sessionStorage.setItem(key, '1');
  } catch (e) {
    return;
  }

  var script = document.createElement('script');
  script.async = true;
  script.src = 'https://stats.jpj.dev/count.js';
  script.setAttribute('data-goatcounter', 'https://stats.jpj.dev/count');
  document.head.appendChild(script);
})();
