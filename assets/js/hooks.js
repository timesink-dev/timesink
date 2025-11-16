import EmblaCarousel from 'embla-carousel'


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

Hooks.EmblaMain = {
  mounted() {
    this.embla = EmblaCarousel(this.el, { loop: true })
    window.__emblaMain__ = this.embla // Make globally available for thumbs

  },

  updated() {
    if (this.embla) this.embla.reInit()
  },

  destroyed() {
    this.embla?.destroy()
  }
}

  Hooks.EmblaThumbs = {
  mounted() {
    

    // Grab reference to the main embla instance (set globally by EmblaMain)
    this.emblaMain = window.__emblaMain__
    this.emblaThumbs = EmblaCarousel(this.el, {
      containScroll: 'keepSnaps',
      dragFree: true,
    })

    // Set up event handlers
    this.setupThumbClicks()
    this.emblaMain.on('init', this.highlightSelected.bind(this))
    this.emblaMain.on('reInit', this.highlightSelected.bind(this))
    this.emblaMain.on('select', this.highlightSelected.bind(this))
  },

  setupThumbClicks() {
    const thumbs = this.el.querySelectorAll('[data-thumb-index]')
    thumbs.forEach((thumb, index) => {
      thumb.addEventListener('click', () => {
        if (!this.emblaMain) return
        this.emblaMain.scrollTo(index)
      })
    })
  },

  highlightSelected() {
    if (!this.emblaMain || !this.emblaThumbs) return

    const selectedIndex = this.emblaMain.selectedScrollSnap()
    const thumbs = this.el.querySelectorAll('[data-thumb-index]')

    thumbs.forEach((thumb, index) => {
      if (index === selectedIndex) {
        thumb.classList.add('ring-2', 'ring-neon-blue-lightest')
        this.emblaThumbs.scrollTo(this.emblaMain.selectedScrollSnap())
      } else {
        thumb.classList.remove('ring-2', 'ring-neon-blue-lightest')
      }
    })
  },

  updated() {
    if (!this.emblaThumbs || !this.emblaMain) return

    const index = this.emblaMain.selectedScrollSnap()
    this.emblaThumbs.reInit()
    this.emblaThumbs.scrollTo(index)
  },

  destroyed() {
    if (this.emblaThumbs) this.emblaThumbs.destroy()
  }
}

Hooks.ScrollObserver = {
  mounted() {
    const threshold = 800; // px

    const indicator = document.getElementById("scroll-indicator");
    const theaterSection = document.getElementById("cinema-barrier");

    if (!indicator || !theaterSection) return;

    const updateVisibility = () => {
      const theaterTop = theaterSection.getBoundingClientRect().bottom;

      if (theaterTop <= threshold) {
        // Theater has entered viewport — hide the indicator
                indicator.classList.remove("opacity-80", "pointer-events-none");

        indicator.classList.add("opacity-0", "pointer-events-none");
      } else {
        // Theater is below viewport — show the indicator
        indicator.classList.remove("opacity-0", "pointer-events-none");
                indicator.classList.add("opacity-80", "pointer-events-none");

      }
    };

    window.addEventListener("scroll", updateVisibility);
    window.addEventListener("resize", updateVisibility);
    updateVisibility(); // Initial check

    this.cleanup = () => {
      window.removeEventListener("scroll", updateVisibility);
      window.removeEventListener("resize", updateVisibility);
    };
  },
  destroyed() {
    this.cleanup && this.cleanup();
  }
};


Hooks.SimulatedLivePlayback = {
  mounted() {
    console.log("SimulatedLivePlayback mounted")

    this.handleEvent("sync_offset", ({ offset }) => {
      const mux = this.el.querySelector("mux-player")
      if (!mux) {
        console.warn("mux-player not found")
        return
      }

      const drift = Math.abs(mux.currentTime - offset)
      console.log(`Current time: ${mux.currentTime}, Offset: ${offset}, Drift: ${drift}`)
      if (drift > 1.5) {
        mux.currentTime = offset
        mux.play().catch(() => {
          console.warn("Autoplay may be blocked until user interaction")
        })
      }
    })
  }
}




Hooks.StripePayment = {
  mounted() {
    if (this.el.dataset.mounted) return;
    this.el.dataset.mounted = "true";

    const appearance = {
      theme: "night",
      labels: "floating",
      variables: {
        colorDanger: "#FF6640",
        colorBackground: "#11182799",
        fontFamily: "Gangster Grotesk, sans-serif",
        fontSmooth: "always",
      },
      rules: {
        ".Input": { backgroundColor: "#11182799", borderColor: "#1f2937" },
        ".Input:focus": { borderColor: "#ADC9FF" },
      },
    };

    const stripe = Stripe(this.el.dataset.stripeKey);
    const elements = stripe.elements({
      clientSecret: this.el.dataset.stripeSecret,
      appearance
    });

    const paymentElement = elements.create("payment", {
      fields: { billingDetails: { name: "never", email: "never" } },
      wallets: { link: "never", applePay: "auto", googlePay: "auto" }
    });

    paymentElement.mount("#payment-element");

    const submitBtn = this.el.querySelector("#stripe-submit");
    const rightSlot = submitBtn?.querySelector("span:last-child"); // our spinner slot
    const errorEl = this.el.querySelector("#card-errors");

    // Enable the button only when Stripe is ready
    paymentElement.on("ready", () => {
      if (submitBtn) submitBtn.disabled = false;
    });

    const setLoading = (isLoading) => {
      if (!submitBtn || !rightSlot) return;
      submitBtn.disabled = !!isLoading;
      submitBtn.setAttribute("aria-busy", String(!!isLoading));

      if (isLoading) {
        rightSlot.innerHTML = `
          <svg aria-hidden="true" role="status" class="w-4 h-4 animate-spin"
               viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" opacity=".25"></circle>
            <path d="M12 2a10 10 0 0 1 10 10" stroke="currentColor" stroke-width="3"></path>
          </svg>`;
      } else {
        rightSlot.innerHTML = ""; // keep the slot, remove spinner
      }
    };

    this.el.addEventListener("submit", async (e) => {
      e.preventDefault();
      if (errorEl) errorEl.textContent = "";
      setLoading(true);

      const { error, paymentIntent } = await stripe.confirmPayment({
        elements,
        confirmParams: {
          return_url: window.location.href,
          payment_method_data: {
            billing_details: {
              name: this.el.dataset.contactName,
              email: this.el.dataset.contactEmail
            }
          }
        },
        redirect: "if_required"
      });

      // If redirect is needed, Stripe will navigate away — spinner stays until navigation.
      // If no redirect, we’re still here:
      if (error) {
        console.error("Payment error:", error.message);
        if (errorEl) errorEl.textContent = error.message;
        setLoading(false);
        return;
      }

      // If we get a PI back with succeeded status (no redirect path)
      if (paymentIntent && paymentIntent.status === "succeeded") {
        // keep spinner briefly or emit an event if you want to move to the next step
        // Example: push a LiveView event or submit a hidden form, etc.
        // setLoading(false); // optionally clear spinner if you stay on the page
      } else {
        // e.g., requires_action handled via redirect (won’t hit here), or processing
        setLoading(false);
      }
    });
  }
};

Hooks.CopyBus = {
  mounted() {
    this.handleEvent("copy_to_clipboard", async ({ text }) => {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        try {
          await navigator.clipboard.writeText(text)
          return
        } catch (err) {
          console.warn("Clipboard API failed:", err)
        }
      }

      // Fallback: use ClipboardItem if supported (modern browsers)
      if (navigator.clipboard && window.ClipboardItem) {
        try {
          const blob = new Blob([text], { type: "text/plain" })
          const data = [new ClipboardItem({ "text/plain": blob })]
          await navigator.clipboard.write(data)
          return
        } catch (err) {
          console.warn("ClipboardItem fallback failed:", err)
        }
      }

      // Last resort: prompt the user to copy manually
      window.prompt("Copy this text:", text)
    })
  }
}

/**  YouTube-style autoscroll:
 - Only stick to bottom when user is already near the bottom
-  If user scrolls up, stop autoscroll and show a "New messages" button
- When user clicks the button or scrolls back to bottom, resume autoscroll 
*/

Hooks.ChatAutoScroll =  {
  STICKY_THRESHOLD: 64, // px from bottom is "at bottom"

  mounted() {
    // This hook must be on the UL. We find the scroll container via data attr.
    const selector = this.el.dataset.scrollContainer;
    this.container = selector ? document.querySelector(selector) : this.el.parentElement;

    if (!this.container) {
      console.warn("[ChatAutoScroll] Missing scroll container for", this.el);
      return;
    }

    // MODE: inline (default) or fixed overlay (set data-overlay="fixed" on the UL)
    this.overlayMode = (this.el.dataset.overlay || "").toLowerCase() === "fixed";

    // state
    this.stickToBottom = true;
    this.isPointerDown = false;
    this.prevCount = this.getMessageCount();
    this.baselineCount = this.prevCount; // count when we left bottom
    this.newCount = 0;

    // ensure predictable stacking
    if (!this.overlayMode) {
      if (!getComputedStyle(this.container).position || getComputedStyle(this.container).position === "static") {
        this.container.style.position = "relative";
      }
      this.container.style.overflowAnchor = "none";
    }

    this.buildJumpButton();
    this.bindEvents();

    // init stickiness
    this.stickToBottom = this.isNearBottom();
    if (this.stickToBottom) this.scrollToBottom(false);
  },

  updated() {
    const currentCount = this.getMessageCount();

    if (this.stickToBottom && !this.isPointerDown) {
      this.scrollToBottom();
      this.hideJumpButton();
      this.baselineCount = currentCount;
      this.newCount = 0;
    } else {
      const diff = Math.max(0, currentCount - this.baselineCount);
      this.newCount = diff;
      this.updateJumpButton();
      if (diff > 0) this.showJumpButton();
    }
  },

  destroyed() {
    this.unbindEvents();
    if (this.jumpBtn && this.overlayMode) {
      // tidy up overlay button if we appended to body
      document.body.contains(this.jumpBtn) && document.body.removeChild(this.jumpBtn);
    }
  },

  // ── events ────────────────────────────────────────────────
  bindEvents() {
    this.onScroll = this.handleScroll.bind(this);
    this.onPointerDown = () => { this.isPointerDown = true; };
    this.onPointerUp = () => { this.isPointerDown = false; };
    this.onReposition = this.positionOverlay.bind(this);

    this.container.addEventListener("scroll", this.onScroll, { passive: true });
    this.container.addEventListener("pointerdown", this.onPointerDown, { passive: true });
    window.addEventListener("pointerup", this.onPointerUp, { passive: true });
    this.container.addEventListener("touchstart", this.onPointerDown, { passive: true });
    window.addEventListener("touchend", this.onPointerUp, { passive: true });

    if (this.overlayMode) {
      window.addEventListener("resize", this.onReposition, { passive: true });
      window.addEventListener("scroll", this.onReposition, { passive: true });
      this.positionOverlay(); // initial placement
    }
  },

  unbindEvents() {
    this.container.removeEventListener("scroll", this.onScroll);
    this.container.removeEventListener("pointerdown", this.onPointerDown);
    window.removeEventListener("pointerup", this.onPointerUp);
    this.container.removeEventListener("touchstart", this.onPointerDown);
    window.removeEventListener("touchend", this.onPointerUp);

    if (this.overlayMode) {
      window.removeEventListener("resize", this.onReposition);
      window.removeEventListener("scroll", this.onReposition);
    }
  },

  // ── behavior ──────────────────────────────────────────────
  getMessageCount() {
    return this.el.querySelectorAll(":scope > li").length; // count direct <li> children
  },

  handleScroll() {
    const dist = this.distanceFromBottom();
    if (dist <= this.STICKY_THRESHOLD) {
      this.stickToBottom = true;
      this.baselineCount = this.getMessageCount();
      this.newCount = 0;
      this.hideJumpButton();
    } else {
      if (this.stickToBottom) this.baselineCount = this.getMessageCount();
      this.stickToBottom = false;
      if (this.overlayMode) this.positionOverlay();
    }
  },

  isNearBottom() { return this.distanceFromBottom() <= this.STICKY_THRESHOLD; },

  distanceFromBottom() {
    const el = this.container;
    return el.scrollHeight - (el.scrollTop + el.clientHeight);
  },

  scrollToBottom(smooth = true) {
    const el = this.container;
    requestAnimationFrame(() => {
      el.scrollTo({ top: el.scrollHeight, behavior: smooth ? "smooth" : "auto" });
    });
  },

  // ── UI: jump button ───────────────────────────────────────
  buildJumpButton() {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.title = "Jump to latest";
    btn.style.display = "none"; // control visibility via inline style
    btn.className = [
      "inline-flex", "items-center", "gap-2",
      "rounded-full", "border", "border-white/10",
      "bg-white/6", "backdrop-blur",
      "px-4", "py-2",
      "text-xs", "font-medium", "text-gray-100",
      "shadow-lg", "hover:bg-white/10",
      "transition-all", "duration-200",
      "animate-in", "slide-in-from-bottom-2"
    ].join(" ");

    if (this.overlayMode) {
      // position: fixed relative to viewport near container's visible bottom-right
      btn.style.position = "fixed";
      btn.style.zIndex = "9999";
      document.body.appendChild(btn);
      this.positionOverlay();
    } else {
      // position: absolute inside scroll container
      btn.style.position = "absolute";
      btn.style.right = "1rem";  // right-4
      btn.style.bottom = "1rem"; // bottom-4
      btn.style.zIndex = "1000";
      this.container.append(btn);
    }

    // Add icon and text
    btn.innerHTML = `
      <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"/>
      </svg>
      <span>New messages</span>
    `;

    btn.addEventListener("click", () => {
      this.stickToBottom = true;
      this.scrollToBottom();
      const current = this.getMessageCount();
      this.baselineCount = current;
      this.newCount = 0;
      this.hideJumpButton();
    });

    this.jumpBtn = btn;
  },

  positionOverlay() {
    if (!this.overlayMode || !this.jumpBtn) return;
    const rect = this.container.getBoundingClientRect();
    // place 16px from bottom center of the visible container for better visibility
    const pad = 16;
    const btnWidth = this.jumpBtn.offsetWidth;
    const x = Math.max(0, rect.left + (rect.width - btnWidth) / 2);
    const y = Math.max(0, rect.bottom - pad - this.jumpBtn.offsetHeight);
    this.jumpBtn.style.left = `${x}px`;
    this.jumpBtn.style.top  = `${y}px`;
  },

  updateJumpButton() {
    if (!this.jumpBtn) return;
    const span = this.jumpBtn.querySelector('span');
    if (span) {
      span.textContent = this.newCount > 0 ? `${this.newCount} new message${this.newCount > 1 ? 's' : ''}` : "New messages";
    }
  },

  showJumpButton() { if (this.jumpBtn) this.jumpBtn.style.display = "inline-flex"; },
  hideJumpButton() { if (this.jumpBtn) this.jumpBtn.style.display = "none"; }
}

export default Hooks;