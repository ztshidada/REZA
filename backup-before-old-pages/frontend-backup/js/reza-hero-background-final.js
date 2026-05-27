(function () {
  const API_BASE =
    location.hostname.includes("localhost")
      ? "http://localhost:10000"
      : "https://api.rezaholdings.co.za";

  function imageUrl(src) {
    if (!src) return null;
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  function findHeroSections() {
    const selectors = [
      ".hero",
      ".home-hero",
      ".page-hero",
      ".landing-hero",
      ".hero-section",
      "section:first-of-type",
      "main section:first-of-type"
    ];

    const found = [];

    selectors.forEach(selector => {
      document.querySelectorAll(selector).forEach(el => {
        if (!found.includes(el)) found.push(el);
      });
    });

    return found;
  }

  async function applyHeroBackground() {
    try {
      const res = await fetch(API_BASE + "/api/media?t=" + Date.now());
      const data = await res.json();

      if (!data.success || !data.media || !data.media.heroImage) {
        console.warn("No hero image found in media API.");
        return;
      }

      const img = imageUrl(data.media.heroImage);
      if (!img) return;

      const sections = findHeroSections();

      sections.forEach(section => {
        section.style.backgroundImage =
          `linear-gradient(90deg, rgba(255,248,238,.90), rgba(255,239,220,.62), rgba(255,220,205,.24)), url("${img}")`;

        section.style.backgroundSize = "cover";
        section.style.backgroundPosition = "center";
        section.style.backgroundRepeat = "no-repeat";
      });

      document.documentElement.style.setProperty("--reza-admin-hero", `url("${img}")`);

      console.log("✅ Reza hero background applied:", sections.length);
    } catch (error) {
      console.error("Hero background failed:", error);
    }
  }

  document.addEventListener("DOMContentLoaded", applyHeroBackground);
  window.addEventListener("load", applyHeroBackground);

  setTimeout(applyHeroBackground, 800);
})();
