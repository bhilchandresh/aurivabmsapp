const fs = require('fs');
const path = require('path');

function walk(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach((file) => {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      results = results.concat(walk(file));
    } else {
      if (file.endsWith('.dart')) results.push(file);
    }
  });
  return results;
}

const invoiceFiles = walk('lib/features/invoices/templates');
const quotationFiles = walk('lib/features/quotations/templates');

invoiceFiles.concat(quotationFiles).forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  let originalContent = content;

  content = content.replace(/'IGST \(18%\)'/g, "'IGST'");
  content = content.replace(/'CGST \(9%\)'/g, "'CGST'");
  content = content.replace(/'SGST \(9%\)'/g, "'SGST'");

  if (content !== originalContent) {
    fs.writeFileSync(file, content);
    console.log("Updated", file);
  }
});
