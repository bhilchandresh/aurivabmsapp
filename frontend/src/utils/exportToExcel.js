import * as XLSX from 'xlsx';

export const exportInvoicesToExcel = (invoices, fileName = 'Gst_Export.xlsx') => {
  if (!invoices || invoices.length === 0) {
    toast.error("No data to export");
    return;
  }

  // --- 1. FLATTEN DATA (Item-wise rows for GST/Tally) ---
  const flattenedData = [];

  invoices.forEach((inv) => {
    const isGst = inv.gstEnabled;
    const invoiceDate = new Date(inv.date).toLocaleDateString('en-GB'); // DD/MM/YYYY for India

    inv.items.forEach((item) => {
      // Calculations per item
      const qty = Number(item.quantity) || 0;
      const rate = Number(item.rate) || 0;
      const amount = qty * rate; // Base Amount
      
      // Discount (Pro-rated per item if global discount exists)
      const discountPercent = Number(inv.discountPercentage) || 0;
      const itemDiscount = amount * (discountPercent / 100);
      const taxableValue = amount - itemDiscount;

      // Tax Logic
      const taxRate = isGst ? (Number(inv.taxRate) || 0) : 0;
      const taxAmount = taxableValue * (taxRate / 100);
      
      // Assuming Intra-State (CGST+SGST) for simplicity
      // For Inter-State (IGST), you need logic based on Client State vs Tenant State
      const cgstRate = taxRate / 2;
      const sgstRate = taxRate / 2;
      const cgstAmount = taxAmount / 2;
      const sgstAmount = taxAmount / 2;

      // Push Row
      flattenedData.push({
        'Invoice Date': invoiceDate,
        'Invoice Number': inv.invoiceNumber,
        'Customer Name': inv.client?.name || 'Cash',
        'Customer GSTIN': inv.client?.gstNumber || 'Unregistered',
        'Place of Supply': inv.client?.address || '', // Ideally should be State Name
        'Item Name': item.description,
        'HSN/SAC': item.hsnCode || '', // You might need to add HSN field in Item schema
        'Quantity': qty,
        'Unit': 'Nos', // Default unit
        'Rate': rate,
        'Total Amount': amount,
        'Discount': itemDiscount.toFixed(2),
        'Taxable Value': taxableValue.toFixed(2),
        'GST Rate (%)': taxRate + '%',
        'CGST Amount': cgstAmount.toFixed(2),
        'SGST Amount': sgstAmount.toFixed(2),
        'IGST Amount': 0, // Logic needed if IGST
        'Cess': 0,
        'Total Invoice Value': (taxableValue + taxAmount).toFixed(2)
      });
    });
  });

  // --- 2. CREATE WORKSHEET ---
  const worksheet = XLSX.utils.json_to_sheet(flattenedData);

  // Column Widths (Optional - for looks)
  const wscols = [
    {wch: 12}, {wch: 15}, {wch: 25}, {wch: 15}, {wch: 15}, 
    {wch: 25}, {wch: 10}, {wch: 8}, {wch: 8}, {wch: 10},
    {wch: 12}, {wch: 10}, {wch: 12}, {wch: 10}, {wch: 12}, {wch: 12}
  ];
  worksheet['!cols'] = wscols;

  // --- 3. CREATE WORKBOOK & DOWNLOAD ---
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, "B2B Invoices");

  XLSX.writeFile(workbook, fileName);
};