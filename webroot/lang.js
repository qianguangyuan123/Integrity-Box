// Load language module dynamically
const langCache = {};

async function _loadLangModule(lang) {
  if (langCache[lang]) return langCache[lang];

  try {
    const mod = await import(`./lang/${lang}.js`);
    const data = {
      translations: mod.translations ?? (mod.default?.translations) ?? {},
      buttonGroups: mod.buttonGroups ?? (mod.default?.buttonGroups) ?? {},
      buttonOrder: mod.buttonOrder ?? (mod.default?.buttonOrder) ?? []
    };
    langCache[lang] = data;
    return data;
  } catch (e) {
    const fileMissing = e.message?.includes("Failed to fetch") || e.message?.includes("404");
    if (fileMissing || lang === "en") {
      console.warn(`No translation file found for "${lang}", using default HTML text.`);
      const data = { translations: null, buttonGroups: null, buttonOrder: null };
      langCache[lang] = data;
      return data;
    }

    // fallback dynamic script load
    return new Promise((resolve) => {
      const prev = document.getElementById("lang-script");
      if (prev) prev.remove();

      window.translations = undefined;
      window.buttonGroups = undefined;
      window.buttonOrder = undefined;

      const s = document.createElement("script");
      s.id = "lang-script";
      s.src = `lang/${lang}.js?_=${Date.now()}`;
      s.defer = true;

      s.onload = async () => {
        let retries = 0;
        while (!window.translations && retries < 20) {
          await new Promise(r => setTimeout(r, 100));
          retries++;
        }
        const data = {
          translations: window.translations ?? {},
          buttonGroups: window.buttonGroups ?? {},
          buttonOrder: window.buttonOrder ?? []
        };
        langCache[lang] = data;
        resolve(data);
      };

      s.onerror = () => {
        console.error(`Failed to load language file: ${lang}`);
        const data = { translations: {}, buttonGroups: {}, buttonOrder: [] };
        langCache[lang] = data;
        resolve(data);
      };

      document.head.appendChild(s);
    });
  }
}

// set button label without affecting icons
function setButtonLabel(btn, text) {
  const icon = btn.querySelector(".icon");
  const spinner = btn.querySelector(".spinner");
  btn.innerHTML = "";
  if (icon) btn.appendChild(icon);
  btn.appendChild(document.createTextNode(" " + text + " "));
  if (spinner) btn.appendChild(spinner);
}

// Change language
async function changeLanguage(lang) {
  if (!lang) lang = localStorage.getItem("lang") || "en";
  localStorage.setItem("lang", lang);

  document.documentElement.setAttribute(
    "dir",
    ["ar", "ur", "fa", "he"].includes(lang) ? "rtl" : "ltr"
  );

  const { translations, buttonGroups, buttonOrder } = await _loadLangModule(lang);
  const isEnglishFallback = !translations && lang === "en";

  // Update group titles
  document.querySelectorAll(".group-title").forEach((title) => {
    const key = title.dataset.key || title.textContent.trim();
    title.dataset.key = key;

    if (!isEnglishFallback) {
      const newText =
        buttonGroups?.[key]?.[lang] ||
        buttonGroups?.[key] ||
        translations?.[key] ||
        title.textContent;
      title.textContent = newText;
    }
  });

  // Update button labels
  const btns = Array.from(document.querySelectorAll(".btn"));
  btns.forEach((btn) => {
    if (!btn.dataset.origLabel) {
      // ignore icons/spinners
      let text = "";
      btn.childNodes.forEach((node) => {
        if (node.nodeType === Node.TEXT_NODE) text += node.textContent;
        else if (
          node.nodeType === Node.ELEMENT_NODE &&
          !node.classList.contains("icon") &&
          !node.classList.contains("spinner")
        ) {
          text += node.textContent;
        }
      });
      btn.dataset.origLabel = text.trim();
    }

    const fallback = btn.dataset.origLabel;

    if (isEnglishFallback) {
      setButtonLabel(btn, fallback);
    } else {
      const scriptName = btn.dataset.script;
      let label = fallback;

      // Use buttonOrder mapping
      if (buttonOrder?.length && translations?.[lang]?.length) {
        const index = buttonOrder.indexOf(scriptName);
        if (index !== -1 && translations[lang][index]) label = translations[lang][index];
      }

      setButtonLabel(btn, label);
    }
  });

  // Update any [data-i18n] elements
  document.querySelectorAll("[data-i18n]").forEach((el) => {
    const key = el.dataset.i18n;
    if (!isEnglishFallback) {
      if (translations?.[key]) el.textContent = translations[key];
      else if (translations?.[lang]?.[key]) el.textContent = translations[lang][key];
    }
  });
}

// Initialize language dropdown
document.addEventListener("DOMContentLoaded", async () => {
  const langDropdown = document.getElementById("lang-dropdown");
  if (!langDropdown) return;

  const savedLang = localStorage.getItem("lang") || "en";
  langDropdown.value = savedLang;

  langDropdown.addEventListener("change", async () => {
    await changeLanguage(langDropdown.value);
  });

  await changeLanguage(savedLang);
});
