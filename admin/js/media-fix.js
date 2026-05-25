const API_BASE =
  location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

function fileToDataUrl(file){
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

document.addEventListener("DOMContentLoaded", () => {
  const saveBtn = [...document.querySelectorAll("button")].find(btn =>
    btn.textContent.trim().toLowerCase() === "save"
  );

  const fileInput = document.querySelector('input[type="file"]');
  const titleInput = document.querySelector('input[type="text"]');

  if(!saveBtn || !fileInput) return;

  saveBtn.addEventListener("click", async (event) => {
    event.preventDefault();

    try {
      saveBtn.textContent = "Saving...";

      let heroImage = null;
      if(fileInput.files && fileInput.files[0]){
        heroImage = await fileToDataUrl(fileInput.files[0]);
      }

      const payload = {
        heroTitle: titleInput ? titleInput.value : "Champagne Luxury"
      };

      if(heroImage){
        payload.heroImage = heroImage;
      }

      const res = await fetch(API_BASE + "/api/media", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      const data = await res.json();

      if(!data.success){
        alert(data.message || "Could not save media.");
        saveBtn.textContent = "Save";
        return;
      }

      alert("Media saved. Refresh the customer homepage.");
      saveBtn.textContent = "Save";
    } catch (error) {
      console.error(error);
      alert("Could not connect to backend API.");
      saveBtn.textContent = "Save";
    }
  });
});
