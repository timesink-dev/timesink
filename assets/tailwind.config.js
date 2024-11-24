// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/timesink_web.ex",
    "../lib/timesink_web/**/*.*ex",
    "../deps/backpex/**/*.*ex",
  ],
  theme: {
    extend: {
      colors: {
        "mystery-white": "#F5F7F9",
        "backroom-black": "#000000",
        "dark-theater-primary": "#222222",
        "dark-theater-medium": "#3B3B3B",
        "dark-theater-light": "#545454",
        "dark-theater-lightest": "#6E6E6E",
        "neon-blue-heavy": "#4987FF",
        "neon-blue-primary": "#7AA8FF",
        "neon-blue-light": "#ADC9FF",
        "neon-blue-lightest": "#E0EBFF",
        "neon-red-primary": "#EC2013",
        "neon-red-light": "#FF6640",
        "neon-red-lightest": "#FE6D48",
        "gray-display-heavy": "#ffffff1a",
        "gray-display-primary": "#D4D6DC",
        "gray-display-medium": "#E3E4E8",
        "gray-display-light": "#F1F2F4",
      },
      fontFamily: {
        brand: ["Ano Regular Wide"],
        brand_italic: ["Ano Regular Wide Italic"],
        gangster: ["Gangster Grotesk"],
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    require("daisyui"),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ]),
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            let size = theme("spacing.6");
            if (name.endsWith("-mini")) {
              size = theme("spacing.5");
            } else if (name.endsWith("-micro")) {
              size = theme("spacing.4");
            }
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: size,
              height: size,
            };
          },
        },
        { values },
      );
    }),
  ],
};
