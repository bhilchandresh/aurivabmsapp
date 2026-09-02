const fs = require('fs');
const path = require('path');

const backendDir = '/Users/apple/Downloads/invoice-system-AURIVA/saas-invoice-app/backend/src/templates';

if (fs.existsSync(backendDir)) {
  const files = fs.readdirSync(backendDir).filter(f => f.endsWith('Template.js'));
  
  files.forEach(f => {
    let templatePath = path.join(backendDir, f);
    let content = fs.readFileSync(templatePath, 'utf8');

    // Add GST to headers
    const headerRegex = /(<th[^>]*>Rate<\/th>)([\s\n]*<th[^>]*>(?:Amount|Total)<\/th>)/g;
    content = content.replace(headerRegex, `$1\n                                       \${isGst ? '<th class="text-right">GST</th>' : ''}$2`);

    // Add GST to cells
    const rowRegex = /(<td[^>]*>\${formatCurrency\(item\.rate\)}<\/td>)([\s\n]*<td[^>]*>\${formatCurrency\(item\.quantity \* item\.rate\)}<\/td>)/g;
    content = content.replace(rowRegex, `$1\n                                       \${isGst ? \`\n                                       <td class="text-right">\n                                          \${item.gstRate ? item.gstRate + '%' : '-'}\n                                       </td>\` : ''}$2`);

    fs.writeFileSync(templatePath, content, 'utf8');
    console.log(`Updated ${templatePath}`);
  });
}

console.log('Done backend updates!');
