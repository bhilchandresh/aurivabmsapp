const fs = require('fs');

let c = fs.readFileSync('lib/features/invoices/templates/minimalist_template.dart', 'utf8');

c = c.replace(/import 'invoice_template_params\.dart';/g, "import 'quotation_template_params.dart';");
c = c.replace(/InvoiceTemplateParams/g, "QuotationTemplateParams");
c = c.replace(/invoiceId/g, "quotationId");

fs.writeFileSync('lib/features/quotations/templates/minimalist_template.dart', c);
