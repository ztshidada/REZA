
const rezaHeroWords = [
  "Repair.",
  "Radiate.",
  "Shine.",
  "Nourish.",
  "Glow Again.",
  "Feel Luxury."
];

let rezaHeroIndex = 0;

function rotateRezaHeroWord() {
  const el = document.querySelector("[data-hero-word]");
  if (!el) return;

  el.classList.remove("word-pop");
  void el.offsetWidth;

  rezaHeroIndex = (rezaHeroIndex + 1) % rezaHeroWords.length;
  el.textContent = rezaHeroWords[rezaHeroIndex];
  el.classList.add("word-pop");
}

document.addEventListener("DOMContentLoaded", () => {
  const el = document.querySelector("[data-hero-word]");
  if (el) {
    el.classList.add("word-pop");
    setInterval(rotateRezaHeroWord, 2100);
  }
});
