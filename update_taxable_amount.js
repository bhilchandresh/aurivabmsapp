const fs = require('fs');
const path = require('path');

const frontendDir = '/Users/apple/Downloads/invoice-system-AURIVA/saas-invoice-app/frontend/src/components/templates';

if (fs.existsSync(frontendDir)) {
  const files = fs.readdirSync(frontendDir).filter(f => f.endsWith('Template.jsx'));
  
  files.forEach(f => {
    let templatePath = path.join(frontendDir, f);
    let content = fs.readFileSync(templatePath, 'utf8');

    // Replace the taxableAmount line
    const regex = /const taxableAmount = subTotal - discountAmount;/g;
    content = content.replace(regex, `const taxableAmount = Number(data.taxableAmount) || (subTotal - discountAmount);`);

    fs.writeFileSync(templatePath, content, 'utf8');
    console.log(`Updated ${templatePath}`);
  });
}

console.log('Done fixing taxableAmount in frontend templates!');
