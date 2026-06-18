const standardTemplate = require('./invoiceTemplate'); // Your existing one
const classicTemplate = require('./classicTemplate');
const minimalistTemplate = require('./minimalistTemplate');
const modernTemplate = require('./modernTemplate');
const modernBlueTemplate = require('./modernBlueTemplate');
const elegantTemplate = require('./elegantTemplate'); // 1. Import
const vibrantTemplate = require('./vibrantTemplate'); // <-- Add Import

module.exports = (templateName, invoice) => {
    switch (templateName) {
        case 'classic':
            return classicTemplate(invoice);
        case 'minimalist':
            return minimalistTemplate(invoice);
        case 'modern':
            return modernTemplate(invoice);
        case 'modern-blue':
            return modernBlueTemplate(invoice);
        case 'elegant': 
            return elegantTemplate(invoice);
        case 'vibrant': 
            return vibrantTemplate(invoice);
        case 'standard':
        default:
            return standardTemplate(invoice);
    }
};