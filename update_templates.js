const fs = require('fs');
const path = require('path');

const frontendDir = '/Users/apple/Downloads/invoice-system-AURIVA/saas-invoice-app/frontend/src/components/templates';
const backendDir = '/Users/apple/Downloads/invoice-system-AURIVA/saas-invoice-app/backend/src/templates';

const templatesToUpdate = [];

if (fs.existsSync(frontendDir)) {
  const files = fs.readdirSync(frontendDir).filter(f => f.endsWith('Template.jsx'));
  files.forEach(f => templatesToUpdate.push({ path: path.join(frontendDir, f), type: 'frontend' }));
}

if (fs.existsSync(backendDir)) {
  const files = fs.readdirSync(backendDir).filter(f => f.endsWith('Template.js'));
  files.forEach(f => templatesToUpdate.push({ path: path.join(backendDir, f), type: 'backend' }));
}

templatesToUpdate.forEach(template => {
  let content = fs.readFileSync(template.path, 'utf8');

  // --- 1. Fix Calculations ---
  // Using a more robust regex that captures from `const subTotal = ` to `return (` or `` `</style> ` `` depending on template type.
  // We'll match everything from `const subTotal = ` up to either `return (` or `return `
  const calcRegex = /const subTotal = data\.items\.reduce[\s\S]*?(?=return \(|return `)/g;

  const calcReplacement = `// Use backend calculated values or fallback
  const subTotal = Number(data.subTotal) || data.items.reduce((sum, item) => sum + (Number(item.quantity) * Number(item.rate)), 0);
  const discountPercentage = Number(data.discountPercentage) || 0;
  const discountAmount = Number(data.discountAmount) || (subTotal * (discountPercentage / 100));
  const taxableAmount = subTotal - discountAmount;
  const taxRate = isGstEnabled ? (Number(data.taxRate) || 0) : 0;
  const taxAmount = Number(data.gstAmount) || (taxableAmount * (taxRate / 100));
  const cgst = data.gstBreakdown?.cgst || taxAmount / 2;
  const sgst = data.gstBreakdown?.sgst || taxAmount / 2;
  const igst = data.gstBreakdown?.igst || 0;
  const total = Number(data.totalAmount) || (taxableAmount + taxAmount);
  const advance = Number(data.advancePayment) || 0;
  const balance = total - advance;

  `;

  if (calcRegex.test(content)) {
    content = content.replace(calcRegex, calcReplacement);
  } else {
    console.log(`Calc regex didn't match in ${template.path}`);
  }

  // --- 2. Fix Table Headers (Frontend JSX) ---
  if (template.type === 'frontend') {
    const headerRegex = /(<th[^>]*>Qty<\/th>\s*)<th([^>]*)>Rate<\/th>(\s*)<th([^>]*)>Amount<\/th>/g;
    content = content.replace(headerRegex, `$1<th$2>Rate</th>\n                                       {isGstEnabled && <th className="py-3 px-2 text-center w-[10%] border-y border-gray-200">GST</th>}$3<th$4>Amount</th>`);

    const rowRegex = /(<td[^>]*>{formatCurrency\(item\.rate\)}<\/td>)(\s*)<td([^>]*)>({formatCurrency\(Number\(item\.quantity\) \* Number\(item\.rate\)\)})<\/td>/g;
    content = content.replace(rowRegex, `$1$2{isGstEnabled && (\n                                              <td className="py-4 px-2 text-center text-gray-600 align-top break-words">\n                                                  {item.gstRate ? \`\${item.gstRate}%\` : '-'}\n                                              </td>\n                                          )}$2<td$3>$4</td>`);
  }

  // --- 3. Fix Table Headers (Backend JS Strings) ---
  if (template.type === 'backend') {
    const headerRegex = /(<th[^>]*>Qty<\/th>[\s\n]*)<th([^>]*)>Rate<\/th>([\s\n]*)<th([^>]*)>Amount<\/th>/g;
    content = content.replace(headerRegex, `$1<th$2>Rate</th>\n                                       \${isGstEnabled ? '<th class="py-3 px-2 text-center w-[10%] border-y border-gray-200">GST</th>' : ''}$3<th$4>Amount</th>`);

    const rowRegex = /(<td[^>]*>\${formatCurrency\(item\.rate\)}<\/td>)([\s\n]*)<td([^>]*)>(\${formatCurrency\(Number\(item\.quantity\) \* Number\(item\.rate\)\)})<\/td>/g;
    content = content.replace(rowRegex, `$1$2\${isGstEnabled ? \`\n                                              <td class="py-4 px-2 text-center text-gray-600 align-top break-words">\n                                                  \${item.gstRate ? item.gstRate + '%' : '-'}\n                                              </td>\` : ''}$2<td$3>$4</td>`);
  }

  fs.writeFileSync(template.path, content, 'utf8');
  console.log(`Updated ${template.path}`);
});

console.log('Done!');
