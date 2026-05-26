const REZA_API = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";

function rezaImage(src){
  if(!src) return "";
  if(src.startsWith("data:image")) return src;
  if(src.startsWith("http")) return src;
  if(src.startsWith("/")) return REZA_API + src;
  return src;
}

async function loadRezaBranding(){
  try{
    const res = await fetch(REZA_API + "/api/media?t=" + Date.now());
    const data = await res.json();
    if(!data.success || !data.media) return;

    if(data.media.logoImage){
      document.querySelectorAll(".logo").forEach(el=>{
        el.innerHTML = `<img src="${rezaImage(data.media.logoImage)}" alt="Reza Logo">`;
      });
    }

    if(data.media.heroImage){
      document.querySelectorAll(".hero").forEach(el=>{
        el.style.backgroundImage = `url("${rezaImage(data.media.heroImage)}")`;
      });
    }
  }catch(e){ console.warn("Branding failed", e); }
}

document.addEventListener("DOMContentLoaded", loadRezaBranding);
