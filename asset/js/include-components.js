document.addEventListener("DOMContentLoaded", () => {
  const targets = document.querySelectorAll("[data-hb-include]");

  targets.forEach(async (target) => {
    const src = target.getAttribute("data-hb-include");

    if (!src) {
      return;
    }

    try {
      const response = await fetch(src);

      if (!response.ok) {
        throw new Error(`${response.status} ${response.statusText}`);
      }

      target.outerHTML = await response.text();
    } catch (error) {
      console.error(`Failed to load component: ${src}`, error);
    }
  });
});
