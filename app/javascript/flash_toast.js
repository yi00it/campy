const FLASH_TIMEOUT = 2000;

const initFlash = (flash) => {
  if (!(flash instanceof HTMLElement)) return;
  if (flash.dataset.toastInitialized === "true") return;

  flash.dataset.toastInitialized = "true";

  const hide = () => {
    if (flash.dataset.toastDismissed === "true") return;
    flash.dataset.toastDismissed = "true";
    flash.classList.add("flash--hidden");
    flash.addEventListener("transitionend", () => {
      flash.remove();
    }, { once: true });
  };

  setTimeout(hide, FLASH_TIMEOUT);
};

const scanFlashes = () => {
  document.querySelectorAll(".flash").forEach(initFlash);
};

const ensureObserver = () => {
  if (window.__campyFlashObserver || !document.body) return;

  window.__campyFlashObserver = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      mutation.addedNodes.forEach((node) => {
        if (!(node instanceof HTMLElement)) return;
        if (node.classList.contains("flash")) {
          initFlash(node);
        }
        node.querySelectorAll?.(".flash").forEach(initFlash);
      });
    });
  });

  window.__campyFlashObserver.observe(document.body, { childList: true, subtree: true });
};

const setupFlashToasts = () => {
  scanFlashes();
  ensureObserver();
};

if (document.readyState !== "loading") {
  setupFlashToasts();
} else {
  document.addEventListener("DOMContentLoaded", setupFlashToasts);
}

document.addEventListener("turbo:load", setupFlashToasts);

document.addEventListener("turbo:render", setupFlashToasts);

// Export function to programmatically create flash messages
window.showFlashToast = (message, type = "notice") => {
  const flash = document.createElement("div");
  flash.className = `flash flash--${type}`;
  flash.textContent = message;

  // Find or create flash container
  let container = document.querySelector(".flash-container");
  if (!container) {
    container = document.createElement("div");
    container.className = "flash-container";
    document.body.appendChild(container);
  }

  container.appendChild(flash);
  initFlash(flash);
};
