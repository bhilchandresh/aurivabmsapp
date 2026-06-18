const fs = require('fs');

const fixAlignment = (file) => {
  let content = fs.readFileSync(file, 'utf8');

  // Replace BILLED TO Expanded
  content = content.replace(
    /\/\/ BILLED TO\s*Expanded\(/,
    "// BILLED TO\n        Expanded(\n          flex: 55,"
  );

  // Replace PAYMENT INFO gap and Expanded
  content = content.replace(
    /const SizedBox\(width: 180\),\s*\/\/ PAYMENT INFO\s*Expanded\(/,
    "const SizedBox(width: 24),\n        // PAYMENT INFO\n        Expanded(\n          flex: 40,"
  );

  fs.writeFileSync(file, content);
};

fixAlignment('lib/features/invoices/templates/minimalist_template.dart');
fixAlignment('lib/features/quotations/templates/minimalist_template.dart');
