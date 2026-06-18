const fs = require('fs');
const path = require('path');

const dir = '/Users/apple/Downloads/invoice-system-AURIVA/saas-invoice-app/frontend/src/components/templates';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.jsx'));

files.forEach(file => {
    const p = path.join(dir, file);
    let content = fs.readFileSync(p, 'utf8');

    // Replaces the mobile class + the md: desktop class with just the desktop class
    content = content.replace(/flex-col md:flex-row/g, 'flex-row');
    content = content.replace(/flex-col-reverse md:flex-row/g, 'flex-row');
    content = content.replace(/text-center md:text-right/g, 'text-right');
    content = content.replace(/text-left md:text-right/g, 'text-right');
    content = content.replace(/items-start md:items-center/g, 'items-center');
    content = content.replace(/items-start md:items-end/g, 'items-end');
    content = content.replace(/w-full md:w-auto/g, 'w-auto');
    content = content.replace(/w-full md:w-\[([^\]]+)\]/g, 'w-[$1]');
    content = content.replace(/min-w-\[600px\] md:min-w-0/g, 'min-w-0');
    content = content.replace(/min-w-\[800px\] md:min-w-0/g, 'min-w-0');
    content = content.replace(/hidden md:block/g, 'block');
    
    // Remove contradictory mobile margins/borders that the md: classes override
    content = content.replace(/mt-\d+ md:mt-0/g, '');
    content = content.replace(/pt-\d+ md:pt-0/g, '');
    content = content.replace(/border-t md:border-none/g, '');
    content = content.replace(/border border-gray-\d+ md:border-none/g, '');
    content = content.replace(/border-t border-gray-\d+ md:border-none/g, '');
    
    // Replace combined responsive padding/gap with just the md: value
    content = content.replace(/([p|m][x|y|t|b|l|r]?-\d+) md:([p|m][x|y|t|b|l|r]?-\d+)/g, '$2');
    content = content.replace(/(gap-\d+) md:(gap-\d+)/g, '$2');
    
    // Finally, strip the 'md:' prefix from any remaining md: classes
    content = content.replace(/\bmd:([a-zA-Z0-9\[\]\-]+)/g, '$1');
    content = content.replace(/\bsm:([a-zA-Z0-9\[\]\-]+)/g, '$1');
    content = content.replace(/\blg:([a-zA-Z0-9\[\]\-]+)/g, '$1');

    fs.writeFileSync(p, content);
});
console.log("Done updating templates!");
