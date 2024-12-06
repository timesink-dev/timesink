const Hooks = {};

Hooks.HideFlash = {
  mounted() {
    setTimeout(() => {
      this.pushEvent("lv:clear-flash", { key: this.el.dataset.key });
      this.el.style.display = "none";
    }, 3000);
  },
};

// We want this to run as soon as possible to minimize
// flashes with the old theme in some situations
const storedTheme = window.localStorage.getItem("backpexTheme");
if (storedTheme != null) {
  document.documentElement.setAttribute("data-theme", storedTheme);
}

Hooks.BackpexThemeSelector = {
  mounted() {
    const form = document.querySelector("#backpex-theme-selector-form");
    const storedTheme = window.localStorage.getItem("backpexTheme");

    // Marking current theme as active
    if (storedTheme != null) {
      const activeThemeRadio = form.querySelector(
        `input[name='theme-selector'][value='${storedTheme}']`,
      );
      activeThemeRadio.checked = true;
    }

    // Event listener that handles the theme changes and store
    // the selected theme in the session and also in localStorage
    window.addEventListener("backpex:theme-change", async (event) => {
      const cookiePath = form.dataset.cookiePath;
      const selectedTheme = form.querySelector(
        'input[name="theme-selector"]:checked',
      );
      if (selectedTheme) {
        window.localStorage.setItem("backpexTheme", selectedTheme.value);
        document.documentElement.setAttribute(
          "data-theme",
          selectedTheme.value,
        );
        await fetch(cookiePath, {
          body: `select_theme=${selectedTheme.value}`,
          method: "POST",
          headers: {
            "Content-type": "application/x-www-form-urlencoded",
            "x-csrf-token": csrfToken,
          },
        });
      }
    });
  },
};

Hooks.ScrollHook = {
  mounted() {
    const theaterSections = document.querySelectorAll(".film-cover-section");

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const theaterId = entry.target.id.split("-")[1];
            this.pushEventTo(this.el, "scroll_to_theater", { id: theaterId });
            history.pushState({}, "", `/now-playing?theater=${theaterId}`);
          }
        });
      },
      { threshold: 0.5 },
    );

    theaterSections.forEach((section) => observer.observe(section));
  },
  updated() {
    const currentTheaterId = this.el.dataset.currentTheaterId;
    const targetSection = document.getElementById(
      `theater-${currentTheaterId}`,
    );

    if (targetSection) {
      targetSection.scrollIntoView({ behavior: "smooth" });
    }
  },
};

Hooks.ScrollToChangeURL = {
  mounted() {
    console.log("mounted");
    const heroSection = document.querySelector(".hero-section");
    const nowPlayingSection = document.querySelector(".now-playing-section");

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            if (entry.target.classList.contains("now-playing-section")) {
              history.pushState({}, "", "/now-playing");
              this.pushEvent("update_route", { page: "now-playing" });
            } else if (entry.target.classList.contains("hero-section")) {
              history.pushState({}, "", "/");
              this.pushEvent("update_route", { page: "home" });
            }
          }
        });
      },
      { threshold: 0.5 },
    );
    console.log("observer", observer);
    observer.observe(heroSection);
    observer.observe(nowPlayingSection);
  },
};

export default Hooks;
