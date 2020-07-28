module.exports = {
  variants: {},
  plugins: [
    require("tailwindcss-transforms")({
      "3d": true
    }),
    require("tailwindcss-tables")()
  ]
};
