const fs = require('fs');
const path = require('path');

function walkDir(dir, callback) {
    fs.readdirSync(dir).forEach(f => {
        let dirPath = path.join(dir, f);
        let isDirectory = fs.statSync(dirPath).isDirectory();
        if (isDirectory) {
            walkDir(dirPath, callback);
        } else {
            callback(dirPath);
        }
    });
}

const frontendSrcPath = '/Users/apple/Downloads/invoice-system-AURIVA/saas-invoice-app/frontend/src';

walkDir(frontendSrcPath, function(filePath) {
    if (filePath.endsWith('.js') || filePath.endsWith('.jsx')) {
        let content = fs.readFileSync(filePath, 'utf8');
        let modified = false;

        // basic -> freelance
        if (content.includes("'basic'")) { content = content.replace(/'basic'/g, "'freelance'"); modified = true; }
        if (content.includes('"basic"')) { content = content.replace(/"basic"/g, '"freelance"'); modified = true; }
        
        // premium -> pro
        if (content.includes("'premium'")) { content = content.replace(/'premium'/g, "'pro'"); modified = true; }
        if (content.includes('"premium"')) { content = content.replace(/"premium"/g, '"pro"'); modified = true; }
        
        // enterprise -> business
        if (content.includes("'enterprise'")) { content = content.replace(/'enterprise'/g, "'business'"); modified = true; }
        if (content.includes('"enterprise"')) { content = content.replace(/"enterprise"/g, '"business"'); modified = true; }

        if (modified) {
            fs.writeFileSync(filePath, content, 'utf8');
            console.log(`Updated ${filePath}`);
        }
    }
});
