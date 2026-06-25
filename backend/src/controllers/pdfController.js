const { chromium } = require('playwright');
const Invoice = require('../models/Invoice');
const getTemplate = require('../templates/index'); 
const nodemailer = require('nodemailer');

const generatePdfBuffer = async (htmlContent) => {
    let browser;
    try {
        browser = await chromium.launch({ headless: true });
        const page = await browser.newPage();
        
        // 👇👇👇 CHANGE IS HERE 👇👇👇
        // 'networkidle' ka matlab hai images load hone ka wait karega
        await page.setContent(htmlContent, { waitUntil: 'networkidle' }); 
        
        const pdfBuffer = await page.pdf({
            format: 'A4',
            printBackground: true,
            margin: { top: '10mm', right: '10mm', bottom: '10mm', left: '10mm' }
        });

        await browser.close();
        return pdfBuffer;

    } catch (error) {
        if (browser) await browser.close();
        throw new Error("PDF Failed: " + error.message);
    }
};

// ... imports same rahenge (Playwright wala code)

exports.downloadInvoicePDF = async (req, res) => {
    try {
        const { id } = req.params;
        
        // 1. Check if Frontend sent HTML
        const { html } = req.body; 

        const invoice = await Invoice.findOne({ _id: id, tenantId: req.user.tenantId });
        if (!invoice) return res.status(404).json({ message: "Invoice not found" });

        let finalHtml = html;

        // Agar Frontend se HTML nahi aayi (Fallback), to purana method use karein
        if (!finalHtml) {
            const templateName = req.query.template || 'standard';
            finalHtml = getTemplate(templateName, invoice);
        }

        // 2. Playwright se PDF banayein
        const pdfBuffer = await generatePdfBuffer(finalHtml);

        // 3. Send PDF
        res.set({
            'Content-Type': 'application/pdf',
            'Content-Length': pdfBuffer.length,
            'Content-Disposition': `attachment; filename="Invoice-${invoice.invoiceNumber}.pdf"`
        });
        
        res.send(pdfBuffer);

    } catch (error) {
        console.error("Download Error:", error.message);
        res.status(500).json({ message: "PDF Failed", error: error.message });
    }
};

// --- PUBLIC VERSION: NO AUTH ---
exports.downloadPublicInvoicePDF = async (req, res) => {
    try {
        const { id } = req.params;
        const { html } = req.body; 

        const invoice = await Invoice.findById(id);
        if (!invoice) return res.status(404).json({ message: "Invoice not found or expired" });

        if (!html) return res.status(400).json({ message: "HTML content is required for public download" });

        const pdfBuffer = await generatePdfBuffer(html);

        res.set({
            'Content-Type': 'application/pdf',
            'Content-Length': pdfBuffer.length,
        });
        
        res.send(pdfBuffer);

    } catch (error) {
        console.error("Public Download Error:", error.message);
        res.status(500).json({ message: "PDF Generation Failed", error: error.message });
    }
};


// 2. QUOTATION DOWNLOAD (✅ Added for Consistency)
exports.downloadQuotationPDF = async (req, res) => {
    try {
        const { html } = req.body;
        if (!html) return res.status(400).json({ message: "No HTML content" });

        const pdfBuffer = await generatePdfBuffer(html);
        res.set({ 'Content-Type': 'application/pdf', 'Content-Length': pdfBuffer.length });
        res.send(pdfBuffer);
    } catch (error) {
        console.error("Quotation PDF Error:", error);
        res.status(500).json({ message: "PDF Failed", error: error.message });
    }
};

// --- PUBLIC VERSION: NO AUTH ---
exports.downloadPublicQuotationPDF = async (req, res) => {
    try {
        const { html } = req.body;
        if (!html) return res.status(400).json({ message: "No HTML content" });

        const pdfBuffer = await generatePdfBuffer(html);
        res.set({ 'Content-Type': 'application/pdf', 'Content-Length': pdfBuffer.length });
        res.send(pdfBuffer);
    } catch (error) {
        console.error("Public Quotation PDF Error:", error);
        res.status(500).json({ message: "PDF Failed", error: error.message });
    }
};


// ... Email aur WhatsApp wale functions same rahenge (ya unhe bhi aise hi update kar sakte hain)

// --- 2. EMAIL ROUTE ---
exports.emailInvoice = async (req, res) => {
    try {
        const { id } = req.params;
        const templateName = req.query.template || 'standard';

        const invoice = await Invoice.findOne({ _id: id, tenantId: req.user.tenantId });
        if (!invoice || !invoice.client.email) return res.status(400).json({ message: "Email not found" });

        const htmlContent = getTemplate(templateName, invoice);
        const pdfBuffer = await generatePdfBuffer(htmlContent);

        const { sendInvoiceEmail } = require('../utils/emailService');
        await sendInvoiceEmail(invoice, pdfBuffer);

        res.json({ success: true, message: "Email sent!" });
    } catch (error) {
        res.status(500).json({ message: "Email failed", error: error.message });
    }
};

// --- 3. WHATSAPP ROUTE ---
exports.whatsappInvoice = async (req, res) => {
    try {
        const { id } = req.params;
        const invoice = await Invoice.findOne({ _id: id, tenantId: req.user.tenantId });
        if (!invoice || !invoice.client.phone) return res.status(400).json({ message: "Phone missing" });
        
        const phone = invoice.client.phone.replace(/\D/g, ''); 
        const link = `https://wa.me/${phone}?text=Invoice%20${invoice.invoiceNumber}`;
        res.json({ success: true, whatsappUrl: link });
    } catch (error) {
        res.status(500).json({ message: "Error", error: error.message });
    }
};