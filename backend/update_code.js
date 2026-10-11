const fs = require('fs');
const path = require('path');

const filesToUpdate = [
    'src/models/Tenant.js',
    'src/middleware/checkSubscription.js',
    'src/controllers/authController.js',
    'src/controllers/paymentController.js',
    'src/controllers/userController.js',
    'src/controllers/inventoryController.js',
    'src/controllers/supplierController.js',
    'src/controllers/superadminController.js',
    'src/config/plans.js'
];

filesToUpdate.forEach(file => {
    const filePath = path.join('/Users/apple/Downloads/invoice-system-AURIVA/saas-invoice-app/backend', file);
    if (fs.existsSync(filePath)) {
        let content = fs.readFileSync(filePath, 'utf8');

        // General plan replacements
        content = content.replace(/'basic'/g, "'freelance'");
        content = content.replace(/"basic"/g, '"freelance"');
        content = content.replace(/'premium'/g, "'pro'");
        content = content.replace(/"premium"/g, '"pro"');
        content = content.replace(/'enterprise'/g, "'business'");
        content = content.replace(/"enterprise"/g, '"business"');

        content = content.replace(/basic:/g, "freelance:");
        content = content.replace(/premium:/g, "pro:");
        content = content.replace(/enterprise:/g, "business:");

        // 'Starter' to 'Freelance'
        content = content.replace(/'Starter'/g, "'Freelance'");
        content = content.replace(/"Starter"/g, '"Freelance"');

        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Updated ${file}`);
    } else {
        console.log(`File not found: ${file}`);
    }
});
