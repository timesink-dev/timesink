const Hooks = {};

Hooks.HideFlash = {
  mounted() {
    setTimeout(() => {
      this.pushEvent("lv:clear-flash", { key: this.el.dataset.key });
      this.el.style.display = "none";
    }, 3000);
  },
};



Hooks.DigitsOnlyAutoTab = {
  mounted() {
    this.el.addEventListener("keydown", (e) => {
      const allowed = ["Backspace", "Tab", "ArrowLeft", "ArrowRight", "Delete"]
      if (!/^\d$/.test(e.key) && !allowed.includes(e.key)) {
        e.preventDefault()
      }
    })

    this.el.addEventListener("input", (e) => {
      // Optional: auto-tab on max length
      const maxLength = this.el.getAttribute("maxlength")
      if (maxLength && e.target.value.length >= parseInt(maxLength)) {
        const form = this.el.form
        const elements = Array.from(form.elements)
        const index = elements.indexOf(this.el)
        if (index !== -1 && elements[index + 1]) {
          elements[index + 1].focus()
        }
      }
    })
  }
}


Hooks.Countdown = {
mounted() {
  this.started = false

  this.handleEvent("start_countdown", ({ to, duration }) => {
    if (this.el.id === to) {
      this.startCountdown(duration)
    }
  })
},
  startCountdown(duration = 60) {
    if (this.started) return
    this.started = true

    const el = this.el
    const span = el.querySelector("[data-role='countdown-timer']")
    const originalText = el.dataset.originalText || el.innerText

    let remaining = duration

    el.disabled = true
    el.classList.add("opacity-50", "pointer-events-none")

    const update = () => {
      if (remaining <= 0) {
        clearInterval(this._interval)
        el.innerText = originalText
        el.disabled = false
        this.started = false
        el.classList.remove("opacity-50", "pointer-events-none")
      } else {
        if (span) {
          span.innerText = remaining
        } else {
          el.innerText = `${originalText} (${remaining}s)`
        }
        remaining--
      }
    }

    this._interval = setInterval(update, 1000)
    update()
  },

  destroyed() {
    clearInterval(this._interval)
  }
}



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
  },
  
  submitFormIfComplete() {
    // Check if all inputs are filled
    const inputs = Array.from(this.el.querySelectorAll('input'));
    const allFilled = inputs.every(input => input.value.length === 1 && /^\d$/.test(input.value));
    
    if (allFilled) {
      const form = this.el.closest('form');
      if (form) {
        // Give a short delay to ensure the last input's change has propagated
        setTimeout(() => {
          form.requestSubmit();
        }, 400);
      }
    }
  },

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

Hooks.ExhibitionDraggable = {
  mounted() {
    this.handleDragStart = (e) => {
      e.dataTransfer.setData("film_id", this.el.dataset.filmId);
    };
    this.el.addEventListener("dragstart", this.handleDragStart);
  },
  destroyed() {
    this.el.removeEventListener("dragstart", this.handleDragStart);
  }
}

Hooks.ExhibitionDropZone = {
  mounted() {
    this.el.addEventListener("dragleave", () => {
      this.el.classList.remove("ring", "ring-neon-blue-lightest");
    });
    this.el.addEventListener("dragover", (e) => { e.preventDefault()

            this.el.classList.add("ring", "ring-neon-blue-lightest");}
);
    
    this.el.addEventListener("drop", (e) => {
      e.preventDefault()
            this.el.classList.remove("ring", "ring-neon-blue-lightest");

      const filmId = e.dataTransfer.getData("film_id")
      const showcaseId = this.el.dataset.showcaseId
      const theaterId = this.el.dataset.theaterId
      this.pushEvent("create_exhibition", {
        film_id: filmId,
        showcase_id: showcaseId,
        theater_id: theaterId
      })
    })
  },

  destroyed() {
    this.el.removeEventListener("dragleave", this.handleDragLeave);
    this.el.removeEventListener("dragover", this.handleDragOver);
    this.el.removeEventListener("drop", this.handleDrop);
  }
}


Hooks.HoverPlay = {
  mounted() {
    const player = this.el;

    // Prevent it from autoplaying on mount
    player.pause();

    const container = player.closest(".group");
    if (container) {
      container.addEventListener("mouseenter", () => {
        player.play().catch(() => {});
      });
      container.addEventListener("mouseleave", () => {
        player.pause();
        player.currentTime = 0;
      });
    }
  },
  destroyed() {
    const container = this.el.closest(".group");
    if (container) {
      container.removeEventListener("mouseenter", this.handleMouseEnter);
      container.removeEventListener("mouseleave", this.handleMouseLeave);
    }
  }
}


export default Hooks;
