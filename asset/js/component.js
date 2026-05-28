document.addEventListener("click", (event) => {
  const tab = event.target.closest(".hb-__p-method-tab[data-method-tab]");

  if (!tab) {
    return;
  }

  const section = tab.closest(".hb-__p-method--tabs");

  if (!section) {
    return;
  }

  const target = tab.dataset.methodTab;
  const tabs = section.querySelectorAll("[data-method-tab]");
  const panels = section.querySelectorAll("[data-method-panel]");

  tabs.forEach((item) => {
    const isActive = item === tab;
    item.classList.toggle("hb-__is-active", isActive);
    item.setAttribute("aria-selected", String(isActive));
  });

  panels.forEach((panel) => {
    panel.classList.toggle(
      "hb-__is-active",
      panel.dataset.methodPanel === target,
    );
  });
});
