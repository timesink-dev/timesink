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

Hooks.AutoFocus = {
  mounted() {
    this.el.addEventListener("input", (e) => {
      let index = parseInt(this.el.getAttribute("phx-value-index"));
      let nextInput = document.querySelector(`[phx-value-index="${index + 1}"]`);
      if (nextInput && e.target.value !== "") {
        nextInput.focus();
      }
    });

    this.el.addEventListener("keydown", (e) => {
      if (e.key === "Backspace" && e.target.value === "") {
        let index = parseInt(this.el.getAttribute("phx-value-index"));
        let prevInput = document.querySelector(`[phx-value-index="${index - 1}"]`);
        if (prevInput) {
          prevInput.focus();
        }
      }
    });
  }
}

Hooks.PasteHandler = {
    mounted() {
    this.el.addEventListener("paste", (e) => {
      let pastedData = e.clipboardData.getData("text");
      this.pushEvent("paste_code", { value: pastedData });
    });
  }
}


Hooks.CodeInputs =  {
  mounted() {
    this.handlePaste = this.handlePaste.bind(this);
    
    // Focus the first input when the component mounts
    const firstInput = this.el.querySelector('input[data-index="0"]');
    if (firstInput) {
      setTimeout(() => firstInput.focus(), 100);
    }
    
    // Add paste event listener to all inputs
    this.el.querySelectorAll('input').forEach(input => {
      input.addEventListener('paste', this.handlePaste);
      
      // Auto-focus next input on input if the current one is filled
      input.addEventListener('input', (e) => {
        const currentIndex = parseInt(e.target.getAttribute('data-index'));
        
        // Clear non-numeric input
        if (!/^\d*$/.test(e.target.value)) {
          e.target.value = e.target.value.replace(/\D/g, '');
        }
        
        // Auto-advance focus if a digit was entered
        if (e.target.value.length === 1) {
          // Push the change immediately to LiveView (don't wait for blur)
          this.pushInputValueChange(input);
          
          const nextInput = this.el.querySelector(`input[data-index="${currentIndex + 1}"]`);
          if (nextInput) {
            nextInput.focus();
          } else {
            // If this is the last input, submit the form
            this.submitFormIfComplete();
          }
        }
      });
      
      // Support backspace to go to previous input
      input.addEventListener('keydown', (e) => {
        const currentIndex = parseInt(e.target.getAttribute('data-index'));
        
        // If backspace is pressed and the input is empty, focus the previous input
        if (e.key === 'Backspace' && e.target.value === '') {
          const prevInput = this.el.querySelector(`input[data-index="${currentIndex - 1}"]`);
          if (prevInput) {
            prevInput.focus();
          }
        }
      });
    });
  },
  
  pushInputValueChange(input) {
    // Get the form
    const form = input.closest('form');
    if (!form) return;
    
    // Create the FormData
    const formData = new FormData(form);
    formData.append("_target", input.name);
    
    // Push change event to LiveView
    this.pushEventTo(form, "update-digit", Object.fromEntries(formData));
  },
  
  // submitFormIfComplete() {
  //   // Check if all inputs are filled
  //   const inputs = Array.from(this.el.querySelectorAll('input'));
  //   const allFilled = inputs.every(input => input.value.length === 1 && /^\d$/.test(input.value));
    
  //   if (allFilled) {
  //     const form = this.el.closest('form');
  //     if (form) {
  //       // Give a short delay to ensure the last input's change has propagated
  //       setTimeout(() => {
  //         form.requestSubmit();
  //       }, 100);
  //     }
  //   }
  // },

  handlePaste(e) {
    e.preventDefault();
    
    // Get pasted text
    const pastedText = (e.clipboardData || window.clipboardData).getData('text');
    
    // If it looks like a verification code (only digits)
    if (/^\d+$/.test(pastedText)) {
      // Get all inputs
      const inputs = Array.from(this.el.querySelectorAll('input'));
      
      // Fill each input with the corresponding digit
      const digits = pastedText.substring(0, inputs.length).split('');
      let allFilled = true;
      
      digits.forEach((digit, index) => {
        if (inputs[index]) {
          inputs[index].value = digit;
          this.pushInputValueChange(inputs[index]);
        } else {
          allFilled = false;
        }
      });
      
      // Focus the last input or the one after the last filled input
      const lastIndex = Math.min(digits.length, inputs.length) - 1;
      if (lastIndex >= 0 && inputs[lastIndex]) {
        inputs[lastIndex].focus();
      }
      
      // If all boxes are filled, trigger form submission
      if (allFilled && digits.length >= inputs.length) {
        this.submitFormIfComplete();
      }
    }
  },

  destroyed() {
    // Clean up event listeners
    this.el.querySelectorAll('input').forEach(input => {
      input.removeEventListener('paste', this.handlePaste);
    });
  }
};


export default Hooks;
