const API = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";

function toggleMenu(){
  const nav = document.getElementById("mainNav");
  if(nav) nav.classList.toggle("open");
}

function img(src){
  if(!src) return "assets/images/reza-card-bg.svg";
  if(src.startsWith("data:image")) return src;
  if(src.startsWith("http")) return src;
  if(src.startsWith("/")) return API + src;
  return src;
}

function money(v){
  return "R " + Number(v || 0).toLocaleString("en-ZA",{minimumFractionDigits:2,maximumFractionDigits:2});
}

function updateCartCount(){
  const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
  const count = cart.reduce((sum,item)=>sum+Number(item.qty||1),0);
  document.querySelectorAll("#cartCount").forEach(el=>el.textContent=count);
}

function addToCart(product){
  const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
  const found = cart.find(item => item.id === product.id);
  if(found) found.qty += 1;
  else cart.push({...product, qty:1});
  localStorage.setItem("reza_cart", JSON.stringify(cart));
  updateCartCount();
  alert("Added to cart");
}

async function loadBranding(){
  try{
    const res = await fetch(API + "/api/media?t=" + Date.now());
    const data = await res.json();
    if(!data.success || !data.media) return;
    if(data.media.logoImage){
      document.querySelectorAll(".logo").forEach(el=>{
        el.innerHTML = `<img src="${img(data.media.logoImage)}" alt="Reza Logo">`;
      });
    }
  }catch(e){}
}

document.addEventListener("DOMContentLoaded",()=>{
  updateCartCount();
  loadBranding();
});
