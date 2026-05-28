(function(){
  const isAdmin = location.pathname.includes("/admin/");
  if(!isAdmin) return;

  const toast = document.createElement("div");
  toast.className = "pwa-toast";
  document.body.appendChild(toast);

  function showToast(message){
    toast.textContent = message;
    toast.classList.add("show");
    clearTimeout(window.__rezaPwaToast);
    window.__rezaPwaToast = setTimeout(() => toast.classList.remove("show"), 4200);
  }

  if("serviceWorker" in navigator){
    window.addEventListener("load", () => {
      navigator.serviceWorker.register("/admin/sw.js", { scope:"/admin/" }).catch(() => {});
    });
  }

  let deferredPrompt = null;
  const installBtn = document.createElement("button");
  installBtn.className = "pwa-install-btn hidden";
  installBtn.type = "button";
  installBtn.textContent = "Install Admin App";
  document.body.appendChild(installBtn);

  window.addEventListener("beforeinstallprompt", event => {
    event.preventDefault();
    deferredPrompt = event;
    installBtn.classList.remove("hidden");
  });

  installBtn.addEventListener("click", async () => {
    if(!deferredPrompt){
      showToast("On iPhone: tap Share, then Add to Home Screen. On Android: use browser menu, then Install app.");
      return;
    }

    deferredPrompt.prompt();
    await deferredPrompt.userChoice.catch(() => null);
    deferredPrompt = null;
    installBtn.classList.add("hidden");
  });

  if(window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone){
    installBtn.classList.add("hidden");
    document.documentElement.classList.add("pwa-standalone");
  }

  setTimeout(() => {
    const isiOS = /iphone|ipad|ipod/i.test(navigator.userAgent);
    const isStandalone = window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone;
    if(isiOS && !isStandalone){
      showToast("iPhone admin app: tap Share, then Add to Home Screen.");
    }
  }, 1800);
})();
