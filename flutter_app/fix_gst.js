const fs = require('fs');
const path = require('path');

const fixIsOutstate = (file) => {
  let content = fs.readFileSync(file, 'utf8');
  let originalContent = content;

  // Replace boolean assignment
  const badLogic = /bool isOutstate = place\.isNotEmpty && !place\.contains\("telangana"\) && !place\.contains\("36"\);/g;
  const goodLogic = `String tenantState = (params.tenant['state'] ?? '').toString().toLowerCase();
    bool isOutstate = false;
    if (place.isNotEmpty && tenantState.isNotEmpty) {
      isOutstate = !place.contains(tenantState) && !tenantState.contains(place);
    } else if (place.isNotEmpty) {
      isOutstate = !place.contains("telangana") && !place.contains("36");
    }`;

  content = content.replace(badLogic, goodLogic);

  // Replace inline if conditions like: 
  const badInline1 = /if \(params\.placeOfSupply\.toLowerCase\(\)\.contains\("telangana"\) \|\| params\.placeOfSupply\.contains\("36"\)\)/g;
  const goodInline1 = `if (params.placeOfSupply.toLowerCase().contains((params.tenant['state'] ?? 'telangana').toString().toLowerCase()) || params.placeOfSupply.contains("36"))`;

  content = content.replace(badInline1, goodInline1);

  const badInline2 = /if \(params\.placeOfSupply\.toLowerCase\(\)\.contains\('telangana'\) \|\| params\.placeOfSupply\.contains\('36'\)\)/g;
  const goodInline2 = `if (params.placeOfSupply.toLowerCase().contains((params.tenant['state'] ?? 'telangana').toString().toLowerCase()) || params.placeOfSupply.contains('36'))`;
  content = content.replace(badInline2, goodInline2);
  
  if (content !== originalContent) {
    fs.writeFileSync(file, content);
    console.log("Updated", file);
  }
};

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

invoiceFiles.concat(quotationFiles).forEach(fixIsOutstate);

// Also fix template_helper.dart explicitly
const helpers = [
  'lib/features/invoices/templates/template_helper.dart',
  'lib/features/quotations/templates/template_helper.dart'
];

helpers.forEach(f => {
  if (fs.existsSync(f)) {
    let c = fs.readFileSync(f, 'utf8');
    c = c.replace(
      /!place\.contains\("telangana"\) &&\s*!place\.contains\("36"\)/g,
      `(params.tenant['state'] != null ? (!place.contains(params.tenant['state']!.toString().toLowerCase())) : (!place.contains("telangana") && !place.contains("36")))`
    );
    fs.writeFileSync(f, c);
    console.log("Fixed helper", f);
  }
});
