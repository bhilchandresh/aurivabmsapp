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

        // Fetch invoice and populate tenant for white-labeled email templates
        const invoice = await Invoice.findOne({ _id: id, tenantId: req.user.tenantId }).populate('tenantId');
        if (!invoice || !invoice.client || !invoice.client.email) {
            return res.status(400).json({ message: "Client email not found" });
        }

        const { sendInvoiceEmail } = require('../utils/emailService');
        
        // PDF attachment is disabled as per business requirements, skip generation.
        await sendInvoiceEmail(invoice, null, invoice.tenantId);

        res.json({ success: true, message: "Email sent!" });
    } catch (error) {
        console.error("Email API Error:", error);
        res.status(500).json({ message: "Email failed", error: error.message });
    }
};

// --- 3. WHATSAPP ROUTE ---
exports.whatsappInvoice = async (req, res) => {
    try {
        const { id } = req.params;
        const invoice = await Invoice.findOne({ _id: id, tenantId: req.user.tenantId }).populate('tenantId');
        if (!invoice || !invoice.client || !invoice.client.phone) return res.status(400).json({ message: "Phone missing" });
        
        const phone = invoice.client.phone.replace(/\D/g, '');
        const companyName = invoice.tenantId ? invoice.tenantId.name : 'Our Company';
        
        const frontendUrl = process.env.FRONTEND_URL || req.get('origin') || 'http://localhost:5173';
        const publicLink = `${frontendUrl}/public/invoice/${invoice._id}`;
        
        const message = `Hello ${invoice.client.name},\n\nHere is your invoice ${invoice.invoiceNumber} from ${companyName} for the amount of ₹${invoice.totalAmount}.\n\nYou can view, download, or print your invoice online using the following link:\n${publicLink}\n\nThank you for your business!\n\nBest Regards,\n${companyName}`;

        const encodedMessage = encodeURIComponent(message);
        const link = `https://wa.me/${phone}?text=${encodedMessage}`;
        res.json({ success: true, whatsappUrl: link });
    } catch (error) {
        res.status(500).json({ message: "Error", error: error.message });
    }
};