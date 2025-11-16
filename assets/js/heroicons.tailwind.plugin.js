const fs = require('fs');
const path = require('path');

function getHeroicons() {
  const heroiconsPath = path.resolve(__dirname, '../../deps/heroicons/optimized');
  const icons = {};

  const sizes = ['16', '20', '24'];
  const types = ['solid', 'outline'];

  sizes.forEach(size => {
    types.forEach(type => {
      const dirPath = path.join(heroiconsPath, size, type);

      if (fs.existsSync(dirPath)) {
        const files = fs.readdirSync(dirPath);

        files.forEach(file => {
          if (file.endsWith('.svg')) {
            const iconName = file.replace('.svg', '');
            const className = `hero-${iconName}${type === 'solid' ? '-solid' : ''}`;
            const svgPath = path.join(dirPath, file);
            const svgContent = fs.readFileSync(svgPath, 'utf8');

            // Extract the SVG content and convert to data URI
            const base64 = Buffer.from(svgContent).toString('base64');
            icons[className] = `url('data:image/svg+xml;base64,${base64}')`;
          }
        });
      }
    });
  });

  return icons;
}

module.exports = function({ addUtilities }) {
  const icons = getHeroicons();
  const utilities = {};

  Object.entries(icons).forEach(([className, maskImage]) => {
    utilities[`.${className}`] = {
      'mask-image': maskImage,
      '-webkit-mask-image': maskImage,
      'mask-size': 'contain',
      '-webkit-mask-size': 'contain',
      'mask-repeat': 'no-repeat',
      '-webkit-mask-repeat': 'no-repeat',
      'mask-position': 'center',
      '-webkit-mask-position': 'center',
      'background-color': 'currentColor',
      'display': 'inline-block',
      'width': '1em',
      'height': '1em',
    };
  });

  addUtilities(utilities);
};
