const MEDIA_API_BASE =
  location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

function readFileAsDataUrl(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(new Error("Could not read file"));
    reader.readAsDataURL(file);
  });
}

document.addEventListener("DOMContentLoaded", () => {
  const saveButton = [...document.querySelectorAll("button")].find(btn =>
    btn.textContent.trim().toLowerCase() === "save"
  );

  const fileInput = document.querySelector('input[type="file"]');
  const titleInput = document.querySelector('input[type="text"]');

  if (!saveButton) {
    console.warn("Save button not found.");
    return;
  }

  saveButton.addEventListener("click", async (event) => {
    event.preventDefault();

    try {
      saveButton.disabled = true;
      saveButton.textContent = "Saving...";

      const payload = {
        heroTitle: titleInput ? titleInput.value.trim() : "Champagne Luxury"
      };

      if (fileInput && fileInput.files && fileInput.files[0]) {
        payload.heroImage = await readFileAsDataUrl(fileInput.files[0]);
      }

      const response = await fetch(MEDIA_API_BASE + "/api/media", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      const data = await response.json();

      if (!data.success) {
        alert(data.message || "Media save failed.");
        return;
      }

      alert("Saved successfully. Now hard refresh the homepage.");
    } catch (error) {
      console.error(error);
      alert("Media save failed. Open Console to see the error.");
    } finally {
      saveButton.disabled = false;
      saveButton.textContent = "Save";
    }
  });
});
