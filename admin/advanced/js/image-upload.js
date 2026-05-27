function readImageFileAsDataUrl(file) {
  return new Promise((resolve, reject) => {
    if (!file) return resolve("");
    if (!file.type || !file.type.startsWith("image/")) {
      return reject(new Error("Please select an image file."));
    }

    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(new Error("Could not read the image file."));
    reader.readAsDataURL(file);
  });
}

function safeImageSrc(value, fallback = "../assets/images/product-placeholder.svg") {
  if (!value) return fallback;
  if (String(value).startsWith("data:image/")) return value;
  if (String(value).startsWith("http")) return value;
  if (String(value).startsWith("../")) return value;
  return "../" + value;
}
