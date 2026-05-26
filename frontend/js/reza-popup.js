(function(){
  const API = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";
  async function run(){
    try{
      const r = await fetch(API + "/api/popup?t=" + Date.now());
      const d = await r.json();
      const p = d.popup || {};
      if(!d.success || !p.enabled) return;
      const el = document.createElement("div");
      el.className = "reza-popup-overlay";
      el.innerHTML = `<div class="reza-popup-card"><button class="reza-popup-close">×</button>${p.image?`<img src="${p.image}" class="reza-popup-img" alt="Special">`:""}<p class="reza-popup-kicker">${p.category||"Specials"}</p><h2>${p.title||"Special"}</h2><p>${p.message||""}</p><a href="${p.buttonLink||"shop.html"}">${p.buttonText||"Shop Now"}</a></div>`;
      document.body.appendChild(el);
      el.querySelector(".reza-popup-close").onclick=()=>el.remove();
      el.onclick=e=>{if(e.target===el)el.remove();}
    }catch(e){console.warn("Popup failed",e)}
  }
  document.addEventListener("DOMContentLoaded",()=>setTimeout(run,800));
})();
