(function(){
  function ready(fn){
    if(document.readyState !== "loading") fn();
    else document.addEventListener("DOMContentLoaded", fn);
  }

  ready(function(){
    injectStyles();
    buildImageViewer();
    buildProductViewer();
    makeImagesClickable();
    makeProductsClickable();

    const obs = new MutationObserver(function(){
      makeImagesClickable();
      makeProductsClickable();
    });

    obs.observe(document.body, { childList:true, subtree:true });
  });

  function injectStyles(){
    if(document.getElementById("reza-clickable-modal-style")) return;

    const style = document.createElement("style");
    style.id = "reza-clickable-modal-style";
    style.textContent = `
      .reza-clickable-img,
      .product-card,
      .product,
      [data-product-id],
      [data-product]{
        cursor:pointer;
      }

      .reza-modal-backdrop{
        position:fixed;
        inset:0;
        z-index:999999;
        background:rgba(0,0,0,.78);
        display:none;
        align-items:center;
        justify-content:center;
        padding:18px;
      }

      .reza-modal-backdrop.show{
        display:flex;
      }

      .reza-image-modal-card{
        position:relative;
        width:min(96vw,1100px);
        max-height:92vh;
        background:#111;
        border-radius:24px;
        overflow:hidden;
        box-shadow:0 30px 100px rgba(0,0,0,.4);
      }

      .reza-image-modal-card img{
        display:block;
        width:100%;
        max-height:88vh;
        object-fit:contain;
        background:#000;
      }

      .reza-product-modal-card{
        position:relative;
        width:min(96vw,980px);
        max-height:92vh;
        overflow:auto;
        background:#fffaf3;
        color:#241812;
        border-radius:28px;
        box-shadow:0 30px 100px rgba(0,0,0,.4);
        display:grid;
        grid-template-columns:1fr 1fr;
      }

      .reza-product-modal-card img{
        width:100%;
        height:100%;
        min-height:430px;
        object-fit:cover;
        background:#f3eadc;
      }

      .reza-product-modal-body{
        padding:28px;
        display:flex;
        flex-direction:column;
        gap:14px;
      }

      .reza-product-modal-body h2{
        margin:0;
        font-size:clamp(28px,4vw,48px);
        line-height:.95;
        letter-spacing:-.05em;
      }

      .reza-product-modal-price{
        font-size:30px;
        font-weight:1000;
        color:#9b6519;
      }

      .reza-product-modal-desc{
        color:rgba(36,24,18,.72);
        line-height:1.55;
      }

      .reza-modal-actions{
        margin-top:auto;
        display:grid;
        grid-template-columns:1fr 1fr;
        gap:10px;
      }

      .reza-modal-btn{
        border:0;
        border-radius:999px;
        padding:14px 18px;
        font-weight:1000;
        cursor:pointer;
      }

      .reza-modal-btn.primary{
        background:linear-gradient(135deg,#f5d36b,#c89334);
        color:#241812;
      }

      .reza-modal-btn.dark{
        background:#241812;
        color:#fffaf3;
      }

      .reza-modal-close{
        position:absolute;
        right:14px;
        top:14px;
        z-index:3;
        width:42px;
        height:42px;
        border:0;
        border-radius:999px;
        background:rgba(0,0,0,.72);
        color:white;
        font-size:24px;
        cursor:pointer;
        display:grid;
        place-items:center;
      }

      .reza-product-modal-card .reza-modal-close{
        background:#241812;
      }

      @media(max-width:760px){
        .reza-product-modal-card{
          grid-template-columns:1fr;
        }

        .reza-product-modal-card img{
          min-height:280px;
          max-height:420px;
        }

        .reza-product-modal-body{
          padding:20px;
        }

        .reza-modal-actions{
          grid-template-columns:1fr;
        }
      }
    `;
    document.head.appendChild(style);
  }

  function buildImageViewer(){
    if(document.getElementById("rezaImageViewer")) return;

    const modal = document.createElement("div");
    modal.id = "rezaImageViewer";
    modal.className = "reza-modal-backdrop";
    modal.innerHTML = `
      <div class="reza-image-modal-card">
        <button class="reza-modal-close" type="button" aria-label="Close">×</button>
        <img alt="Bigger preview">
      </div>
    `;
    document.body.appendChild(modal);

    modal.addEventListener("click", function(e){
      if(e.target === modal || e.target.classList.contains("reza-modal-close")){
        modal.classList.remove("show");
      }
    });
  }

  function buildProductViewer(){
    if(document.getElementById("rezaProductViewer")) return;

    const modal = document.createElement("div");
    modal.id = "rezaProductViewer";
    modal.className = "reza-modal-backdrop";
    modal.innerHTML = `
      <div class="reza-product-modal-card">
        <button class="reza-modal-close" type="button" aria-label="Close">×</button>
        <img class="reza-product-modal-img" alt="Product preview">
        <div class="reza-product-modal-body">
          <h2 class="reza-product-modal-title">Product</h2>
          <div class="reza-product-modal-price"></div>
          <p class="reza-product-modal-desc"></p>
          <div class="reza-modal-actions">
            <button class="reza-modal-btn primary reza-modal-add-cart" type="button">Add to Cart</button>
            <button class="reza-modal-btn dark reza-modal-close-2" type="button">Continue Shopping</button>
          </div>
        </div>
      </div>
    `;
    document.body.appendChild(modal);

    modal.addEventListener("click", function(e){
      if(e.target === modal || e.target.classList.contains("reza-modal-close") || e.target.classList.contains("reza-modal-close-2")){
        modal.classList.remove("show");
      }
    });
  }

  function makeImagesClickable(){
    const page = location.pathname.toLowerCase();

    document.querySelectorAll("img").forEach(function(img){
      if(img.dataset.rezaClickableDone) return;

      const src = img.getAttribute("src") || "";
      const isTestimony =
        page.includes("testimony") ||
        src.includes("testimon") ||
        img.closest(".testimony-card");

      if(!isTestimony) return;

      img.dataset.rezaClickableDone = "1";
      img.classList.add("reza-clickable-img");

      img.addEventListener("click", function(e){
        e.preventDefault();
        e.stopPropagation();

        const modal = document.getElementById("rezaImageViewer");
        const modalImg = modal.querySelector("img");
        modalImg.src = img.currentSrc || img.src;
        modalImg.alt = img.alt || "Bigger preview";
        modal.classList.add("show");
      });
    });
  }

  function makeProductsClickable(){
    const candidates = document.querySelectorAll(".product-card, .product, [data-product-id], [data-product]");

    candidates.forEach(function(card){
      if(card.dataset.rezaProductClickableDone) return;
      if(card.closest("#rezaProductViewer")) return;

      const img = card.querySelector("img");
      const titleEl = card.querySelector("h1,h2,h3,.title,.name,.product-title,.product-name");
      const priceEl = card.querySelector(".price,.product-price,[data-price]");
      const descEl = card.querySelector(".description,.desc,.product-description,p");

      if(!img && !titleEl) return;

      card.dataset.rezaProductClickableDone = "1";

      card.addEventListener("click", function(e){
        const tag = (e.target.tagName || "").toLowerCase();
        if(["button","a","input","select","textarea"].includes(tag)) return;

        const modal = document.getElementById("rezaProductViewer");
        const modalImg = modal.querySelector(".reza-product-modal-img");
        const modalTitle = modal.querySelector(".reza-product-modal-title");
        const modalPrice = modal.querySelector(".reza-product-modal-price");
        const modalDesc = modal.querySelector(".reza-product-modal-desc");
        const addBtn = modal.querySelector(".reza-modal-add-cart");

        modalImg.src = img ? (img.currentSrc || img.src) : "";
        modalTitle.textContent = titleEl ? titleEl.textContent.trim() : "Product";
        modalPrice.textContent = priceEl ? priceEl.textContent.trim() : "";
        modalDesc.textContent = descEl ? descEl.textContent.trim() : "View product details and add it to your cart.";

        addBtn.onclick = function(){
          const existingAdd =
            card.querySelector(".add-to-cart, [data-add-to-cart], button");

          if(existingAdd){
            existingAdd.click();
          } else {
            window.location.href = "shop.html";
          }

          modal.classList.remove("show");
        };

        modal.classList.add("show");
      });
    });
  }

  document.addEventListener("keydown", function(e){
    if(e.key === "Escape"){
      document.querySelectorAll(".reza-modal-backdrop.show").forEach(m => m.classList.remove("show"));
    }
  });
})();
