import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu", "label"];

  connect() {
    const currentLocale = this.extractLocaleFromCookie() || this.extractLocaleFromPath() || "en";
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

  extractLocaleFromPath() {
    const path = window.location.pathname;
    // Only "cn" and "tw" are valid locale prefixes; "en" has no prefix
    const match = path.match(/^\/(cn|tw)(\/|$)/);
    return match ? match[1] : null;
  }

  updateLabel(locale) {
    const labels = { en: "EN", cn: "简", tw: "繁" };
    this.labelTarget.textContent = labels[locale] || "EN";
  }

  navigateToLocale(locale) {
    const path = window.location.pathname;
    let newPath;

    // Check if we're on an article (with or without locale prefix)
    const articleMatch = path.match(/^\/?(?:cn|tw)?\/?([a-z0-9]{2})$/) || path.match(/^\/([a-z0-9]{2})$/);

    // Check if we're on /articles or /cn/articles or /tw/articles
    const articlesMatch = path.match(/^\/?(?:cn|tw)?\/?(articles)$/);

    if (articleMatch) {
      // Article route: adjust locale prefix
      const slug = articleMatch[1];
      if (locale === "en") {
        newPath = `/${slug}`;
      } else {
        newPath = `/${locale}/${slug}`;
      }
    } else if (articlesMatch) {
      // Articles list route: adjust locale prefix
      if (locale === "en") {
        newPath = "/articles";
      } else {
        newPath = `/${locale}/articles`;
      }
    } else {
      // Other routes (contracts, home, etc.): cookie is set, force reload
      window.location.reload();
      return;
    }

    window.location.pathname = newPath;
  }
}
