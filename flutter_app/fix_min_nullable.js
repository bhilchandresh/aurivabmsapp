const fs = require('fs');

const fixIsNotEmpty = (file) => {
  let content = fs.readFileSync(file, 'utf8');

  content = content.replace(
    /params\.tenant\['signatureImage'\] != null && params\.tenant\['signatureImage'\]\.isNotEmpty/g,
    "(params.tenant['signatureImage']?.toString() ?? '').isNotEmpty"
  );

  fs.writeFileSync(file, content);
};

fixIsNotEmpty('lib/features/invoices/templates/minimalist_template.dart');
fixIsNotEmpty('lib/features/quotations/templates/minimalist_template.dart');
