(function(){
  function addTableLabels(){
    document.querySelectorAll("table").forEach(table => {
      const headers = Array.from(table.querySelectorAll("thead th")).map(th => th.textContent.trim() || "Action");

      table.querySelectorAll("tbody tr").forEach(row => {
        Array.from(row.children).forEach((cell, index) => {
          if(!cell.getAttribute("data-label")){
            cell.setAttribute("data-label", headers[index] || "");
          }
        });
      });
    });
  }

  function addBottomNav(){
    if(document.querySelector(".wx-mobile-bottom")) return;

    const nav = document.createElement("nav");
    nav.className = "wx-mobile-bottom";
    nav.innerHTML = `
      <a href="dashboard.html">🏠<span>Home</span></a>
      <a href="orders.html">🧾<span>Orders</span></a>
      <a href="products.html">🛍️<span>Products</span></a>
      <a href="media.html">🖼️<span>Media</span></a>
    `;
    document.body.appendChild(nav);

    const page = location.pathname.split("/").pop();
    document.querySelectorAll(".wx-mobile-bottom a").forEach(a => {
      if(a.getAttribute("href") === page) a.classList.add("active");
    });
  }

  addTableLabels();
  addBottomNav();

  const obs = new MutationObserver(() => addTableLabels());
  obs.observe(document.body, { childList:true, subtree:true });
})();
