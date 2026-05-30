
const REZA_API_BASE_MEDIA = "https://api.rezaholdings.co.za";

function mediaImageSrc(value) {
  if (!value) return "";
  if (String(value).startsWith("data:image/")) return value;
  if (String(value).startsWith("http")) return value;
  if (String(value).startsWith("../")) return value.replace("../", "");
  return value;
}

async function getLiveMedia() {
  try {
    const res = await fetch(`${REZA_API_BASE_MEDIA}/api/media`, { cache: "no-store" });
    const data = await res.json();

    if (data.success && data.media) {
      localStorage.setItem("reza_media_cache", JSON.stringify(data.media));
      return data.media;
    }
  } catch (error) {
    console.warn("Could not load backend media:", error.message);
  }

  try {
    return JSON.parse(localStorage.getItem("reza_media_cache") || "{}");
  } catch {
    return {};
  }
}

async function applyLiveMedia() {
  const media = await getLiveMedia();

  const bg1 = mediaImageSrc(media.background1 || "assets/images/background-image-1.png");
  const bg2 = mediaImageSrc(media.background2 || "assets/images/background-image-2.png");
  const bg3 = mediaImageSrc(media.background3 || "assets/images/background-image-3.png");
  const logo = mediaImageSrc(media.logo || "assets/images/reza-logo.png");

  document.documentElement.style.setProperty("--reza-bg-1", `url("${bg1}")`);
  document.documentElement.style.setProperty("--reza-bg-2", `url("${bg2}")`);
  document.documentElement.style.setProperty("--reza-bg-3", `url("${bg3}")`);

  document.querySelectorAll("img[src*='reza-logo.png'], img[data-reza-logo]").forEach(img => {
    img.src = logo;
  });

  document.body.classList.add("media-loaded");
}

document.addEventListener("DOMContentLoaded", applyLiveMedia);
