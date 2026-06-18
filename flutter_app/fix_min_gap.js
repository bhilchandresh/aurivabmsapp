const fs = require('fs');

const fixGap = (file) => {
  let content = fs.readFileSync(file, 'utf8');

  // Find the boundary between the two Expanded widgets in _buildClientAndPaymentInfo
  const searchPattern = /        \),\s*\/\/\s*PAYMENT INFO\s*Expanded\(/;
  
  if (searchPattern.test(content)) {
    content = content.replace(searchPattern, 
      `        ),
        const SizedBox(width: 40),
        // PAYMENT INFO
        Expanded(`
    );
    fs.writeFileSync(file, content);
  }
};

fixGap('lib/features/invoices/templates/minimalist_template.dart');
fixGap('lib/features/quotations/templates/minimalist_template.dart');
