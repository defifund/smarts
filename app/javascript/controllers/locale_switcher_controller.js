import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu", "label"];
  static supportedChains = ["eth", "base", "arbitrum", "optimism", "bnb", "polygon"];

  connect() {
    const currentLocale = this.extractLocaleFromPath() || this.extractLocaleFromHtmlLang() || this.extractLocaleFromCookie() || "en";
    this.updateLabel(currentLocale);
  }

  toggle(event) {
    event.preventDefault();
    this.menuTarget.classList.toggle("hidden");
  }

  select(event) {
    event.preventDefault();
    const selectedLocale = event.target.dataset.locale;
    localStorage.setItem("smarts_locale", selectedLocale);
    document.cookie = `locale=${selectedLocale};path=/;max-age=${365 * 24 * 60 * 60};SameSite=Lax`;
    this.navigateToLocale(selectedLocale);
  }

  extractLocaleFromCookie() {
    const match = document.cookie.match(/(?:^|;\s*)locale=(\w+)/);
    return match ? match[1] : null;
  }

  extractLocaleFromHtmlLang() {
    const lang = document.documentElement.lang;
    if (lang === "zh-CN") return "cn";
    if (lang === "zh-TW") return "tw";
    if (lang === "en") return "en";
    return null;
  }

  extractLocaleFromPath() {
    const path = window.location.pathname;
    const match = path.match(/^\/(cn|tw)(?:\/|$)/);
    return match ? match[1] : null;
  }

  stripLocalePrefix(path) {
    return path.replace(/^\/(cn|tw)(?=\/)/, "");
  }

  isArticlePath(path) {
    const cleanPath = this.stripLocalePrefix(path);
    return /^\/?(?:articles|[a-z0-9]{2})$/.test(cleanPath);
  }

  isChainAddressPath(chain, address) {
    return this.constructor.supportedChains.includes(chain) && /^0x[0-9a-fA-F]{40}(?:\.md)?$/.test(address);
  }

  isContractPath(path) {
    const cleanPath = this.stripLocalePrefix(path);
    const segments = cleanPath.split("/").filter(Boolean);

    if (segments.length === 1) {
      return /-(eth|base|arbitrum|optimism|bnb|polygon)(?:\.md)?$/i.test(segments[0]);
    }

    if (segments.length === 2) {
      return this.isChainAddressPath(segments[0], segments[1]);
    }

    return false;
  }

  currentContractPath(locale) {
    const localePrefix = locale === "en" ? "" : `/${locale}`;
    const cleanPath = this.stripLocalePrefix(window.location.pathname);
    const segments = cleanPath.split("/").filter(Boolean);

    if (segments.length === 1) {
      return `${localePrefix}/${segments[0]}`;
    }

    if (segments.length === 2 && this.isChainAddressPath(segments[0], segments[1])) {
      return `${localePrefix}/${segments[0]}/${segments[1]}`;
    }

    return null;
  }

  updateLabel(locale) {
    const labels = { en: "EN", cn: "简", tw: "繁" };
    this.labelTarget.textContent = labels[locale] || "EN";
  }

  navigateToLocale(locale) {
    const path = window.location.pathname;
    let newPath;

    // Check if we're on home (/ or /cn or /tw) — must be checked BEFORE articleMatch
    // because /tw matches the 2-char article pattern
    const homeMatch = path.match(/^\/(?:cn|tw)?$/) || path === "/";

    // Check if we're on an article (with or without locale prefix)
    const articleMatch = path.match(/^\/?(?:cn|tw)?\/?([a-z0-9]{2})$/) || path.match(/^\/([a-z0-9]{2})$/);

    // Check if we're on /articles or /cn/articles or /tw/articles
    const articlesMatch = path.match(/^\/?(?:cn|tw)?\/?(articles)$/);

    // Check if we're on /mcp (no locale prefix needed)
    const mcpMatch = path === "/mcp";

    if (homeMatch) {
      // Home route: adjust locale prefix
      if (locale === "en") {
        newPath = "/";
      } else {
        newPath = `/${locale}`;
      }
    } else if (articleMatch) {
      // Article route: adjust locale prefix
      const slug = articleMatch[1];
      if (locale === "en") {
        newPath = `/${slug}`;
      } else {
        newPath = `/${locale}/${slug}`;
      }
    } else if (this.isContractPath(path)) {
      newPath = this.currentContractPath(locale);
    } else if (articlesMatch) {
      // Articles list route: adjust locale prefix
      if (locale === "en") {
        newPath = "/articles";
      } else {
        newPath = `/${locale}/articles`;
      }
    } else if (mcpMatch) {
      // MCP route: no URL change needed, locale is set via cookie, just reload
      window.location.reload();
      return;
    } else {
      // Other routes (admin, etc.): cookie is set, force reload
      window.location.reload();
      return;
    }

    if (!newPath) {
      window.location.reload();
      return;
    }

    window.location.pathname = newPath;
  }
}
