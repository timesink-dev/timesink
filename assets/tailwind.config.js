module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/timesink_web.ex",
    "../lib/timesink_web/**/*.*ex",
    "../deps/backpex/**/*.*ex",
    "../deps/backpex/assets/js/**/*.*js",
  ],
  theme: {
    extend: {
      colors: { /* keep for now, we’ll move to CSS */ },
      fontFamily: { /* keep for now, we’ll move to CSS */ },
    },
  },
  plugins: [
    // ⚠️ remove daisyui, we’ll load it from CSS
    // require("daisyui"),

    // you *can* keep other plugins temporarily, but the end goal is to move
    // them to CSS too
  ],
};
