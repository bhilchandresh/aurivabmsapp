const fs = require('fs');

const fixGap = (file) => {
  let content = fs.readFileSync(file, 'utf8');

  // Replace 80 with 180
  content = content.replace(/const SizedBox\(width: 80\)/g, "const SizedBox(width: 180)");

  fs.writeFileSync(file, content);
};

fixGap('lib/features/invoices/templates/minimalist_template.dart');
fixGap('lib/features/quotations/templates/minimalist_template.dart');
