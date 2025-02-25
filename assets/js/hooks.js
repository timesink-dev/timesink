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

let isNavigating = false;

Hooks.ScrollToTheater = {
  mounted() {
    const theaterSections = document.querySelectorAll(".film-cover-section");
    const observer = new IntersectionObserver(
      (entries) => {
        if (isNavigating) {
          return;
        }
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const theaterId = entry.target.id.split("-")[1];
            console.log({ theaterId });
            this.pushEventTo(this.el, "scroll_to_theater", { id: theaterId });
            history.pushState({}, "", `/now-playing?theater=${theaterId}`);
          }
        });
      },
      { threshold: .8 },
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
  destroyed() {
    if (this.observer) {
      this.observer.disconnect(); // Clean up observer on destruction
    }
  },
};

Hooks.NavigateToTheater = {
  updated() {
    isNavigating = true;
    const currentTheaterId = this.el.dataset.currentTheaterId;
    const targetSection = document.getElementById(
      `theater-${currentTheaterId}`,
    );

    if (targetSection) {
      targetSection.scrollIntoView({ behavior: "smooth" });
    }
    setTimeout(() => {
      isNavigating = false;
    }, 500);
  },
};

Hooks.ScrollHandler = {
  mounted() {
    this.sections = Array.from(this.el.querySelectorAll(".theater-section"));
    this.navItems = Array.from(this.el.querySelectorAll('a[href^="#theater-"]'));

    // If there's a hash in the URL on page load, scroll to the target section
    const initialHash = window.location.hash.slice(1);
    if (initialHash) {
      this.scrollToSection(initialHash);
    }
    // Attach click event to nav items for smooth scroll
    this.navItems.forEach((navItem) => {
      navItem.addEventListener("click", (event) => this.handleNavClick(event));
    });

    // Attach the scroll event listener
    this.scrollHandler = () => this.updateActiveSection();
    window.addEventListener("scroll", this.scrollHandler);

  },

  destroyed() {
    // Clean up event listeners
    window.removeEventListener("scroll", this.scrollHandler);
    this.navItems.forEach((navItem) => {
      navItem.removeEventListener("click", (event) => this.handleNavClick(event));
    });
  },

  scrollToSection(id, behavior) {
    const targetSection = document.getElementById(id);
    if (targetSection) {
      targetSection.scrollIntoView({ behavior: behavior ?? 'smooth', block: "center" });
      this.updateActiveNavItem(id);
    }
  },

  handleNavClick(event) {
    event.preventDefault();
    const targetId = event.currentTarget.getAttribute("href").slice(1);
    console.log({targetId})
    this.scrollToSection(targetId, 'instant');
  },

  updateURL(id) {
    const newURL = `${window.location.origin}/#${id}`;
    history.replaceState(null, "", newURL); // Updates the URL without reloading
  },

  updateActiveNavItem(currentSectionId) {
    console.log('update current item')
    this.navItems.forEach((navItem) => {
      navItem.classList.remove("active");
      if (navItem.id === `nav-${currentSectionId}`) {
        navItem.classList.add("active");
      }
    });
  },

  updateActiveSection() {
    let currentSectionId = null;

    // Find the section currently in view
    this.sections.forEach((section) => {
      const sectionTop = section.offsetTop - window.innerHeight / 2;
      if (window.scrollY >= sectionTop) {
        currentSectionId = section.id;
      }
    });

    if (currentSectionId) {
      this.updateURL(currentSectionId);
      this.updateActiveNavItem(currentSectionId);
    }
  },
}

export default Hooks;
