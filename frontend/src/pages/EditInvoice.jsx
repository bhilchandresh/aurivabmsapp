import React, { useState, useEffect, useContext, Fragment } from "react";
import { useForm, useFieldArray } from "react-hook-form";
import api from "../utils/api";
import toast from "react-hot-toast";
import { useParams, useNavigate, Link } from "react-router-dom";
import { ArrowLeft, Save, Plus, Trash2, Calendar, FileText, User, CreditCard, AlertCircle } from "lucide-react";
import { useQueryClient } from '@tanstack/react-query';
import Layout from "../components/Layout";
import { AuthContext } from "../context/AuthContext";
import ClientAutocomplete from "../components/ClientAutocomplete";
import { INDIAN_STATES } from "../utils/constants";

const EditInvoice = () => {
   const { id } = useParams();
   const { token } = useContext(AuthContext);
   const navigate = useNavigate();

   const [clients, setClients] = useState([]);
   const [inventoryItems, setInventoryItems] = useState([]);
   const [loading, setLoading] = useState(true);
   const [gstEnabled, setGstEnabled] = useState(false); // Toggle State
   const [tenantState, setTenantState] = useState("");
   const [taxType, setTaxType] = useState("exclusive");

   // --- CUSTOM API ERROR STATE ---
   const [apiError, setApiError] = useState(null);
   const queryClient = useQueryClient();

   // Form Setup
   const { register, control, handleSubmit, watch, setValue, reset, formState: { errors } } = useForm({
      defaultValues: { items: [], taxRate: 18, advancePayment: 0, discountPercentage: 0, placeOfSupply: "" }
   });

   const { fields, append, remove } = useFieldArray({ control, name: "items" });

   // Watch values for real-time calculations
   const items = watch("items");
   const taxRate = watch("taxRate");
   const discountPercentage = watch("discountPercentage");
   const advancePayment = watch("advancePayment");
   const invoiceNumber = watch("invoiceNumber");
   const placeOfSupply = watch("placeOfSupply");

   // Watch Date for Validation
   const invoiceDate = watch("date");


   // 1. Fetch Data
   useEffect(() => {
      const init = async () => {
         try {
            const [resInvoice, resClients, resInventory, resSettings] = await Promise.all([
               api.get(`/invoices/${id}`),
               api.get(`/clients`),
               api.get(`/inventory`),
               api.get(`/auth/settings`)
            ]);

            const inv = resInvoice.data.data;
            setClients(resClients.data.data);
            setInventoryItems(resInventory.data.data);
            setGstEnabled(inv.gstEnabled);
            setTaxType(inv.taxType || "exclusive");
            
            if (resSettings.data.data.state) {
               setTenantState(resSettings.data.data.state);
            } else if (resSettings.data.data.address) {
               // Fallback: try to find state in address string if state field is empty
               const foundState = INDIAN_STATES.find(s => 
                  resSettings.data.data.address.toLowerCase().includes(s.toLowerCase())
               );
               if (foundState) setTenantState(foundState);
            }

            // Pre-fill Form
            reset({
               client: inv.client,
               clientId: inv.client?.clientId,
               items: inv.items.map(item => {
                  const invItem = resInventory.data.data.find(i => i._id === item.inventoryId);
                  const availableStock = invItem ? (invItem.currentStock + item.quantity) : null;
                  return {
                     ...item,
                     gstRate: item.gstRate || inv.taxRate || 18,
                     hsnCode: item.hsnCode || "",
                     additionalDetails: item.additionalDetails || "",
                     availableStock: availableStock
                  };
               }),
               taxRate: inv.taxRate || 18,
               discountPercentage: inv.discountPercentage || 0,
               advancePayment: inv.advancePayment || 0,
               terms: inv.terms,
               invoiceNumber: inv.invoiceNumber,
               status: inv.status,
               placeOfSupply: inv.placeOfSupply || inv.client?.state || "",
               date: inv.date ? inv.date.split('T')[0] : '',
               dueDate: inv.dueDate ? inv.dueDate.split('T')[0] : ''
            });
            setLoading(false);
         } catch (err) {
            setApiError("Error loading invoice details.");
            setLoading(false);
         }
      };
      if (token) init();
   }, [id, token, reset]);

   // Handle Client Change
   const handleClientSelect = (client) => {
      if (client) {
         setValue("client.name", client.name);
         setValue("client.email", client.email);
         setValue("client.address", client.address);
         setValue("client.gstin", client.gstin || client.gstNumber);
         setValue("client.state", client.state);
         setValue("clientId", client._id);
         setValue("placeOfSupply", client.state);
      }
   };

    // 3. CALCULATIONS
    const isInterState = React.useMemo(() => {
        if (!tenantState || !placeOfSupply) return false;
        return tenantState.trim().toLowerCase() !== placeOfSupply.trim().toLowerCase();
    }, [tenantState, placeOfSupply]);

   let calculatedSubTotal = 0;
   let calculatedTaxAmount = 0;

   const processedItems = items ? items.map(item => {
      const qty = Number(item.quantity) || 0;
      const rate = Number(item.rate) || 0;
      const itemGstRate = gstEnabled ? (Number(item.gstRate) || 0) : 0;
      
      let lineTotal = qty * rate;
      let taxable = lineTotal;
      let tax = 0;

      if (gstEnabled) {
         if (taxType === 'inclusive') {
            taxable = lineTotal / (1 + (itemGstRate / 100));
            tax = lineTotal - taxable;
         } else {
            tax = lineTotal * (itemGstRate / 100);
            lineTotal = lineTotal + tax;
         }
      }
      
      calculatedSubTotal += taxable;
      calculatedTaxAmount += tax;
      
      return { ...item, taxable, tax, lineTotal };
   }) : [];

   const subTotal = calculatedSubTotal;
   const discountAmount = subTotal * (Number(discountPercentage) / 100);
   
   // Calculate actual taxable value (only items with GST > 0)
   const taxableItemsSubTotal = processedItems.reduce((sum, item) => sum + ((Number(item.gstRate) > 0) ? Number(item.taxable) : 0), 0);
   
   // Apply proportional discount to taxable amount
   const taxableAmount = gstEnabled ? (taxableItemsSubTotal * (1 - (Number(discountPercentage) / 100))) : (subTotal - discountAmount);
   
   const gstAmount = calculatedTaxAmount * (1 - (Number(discountPercentage) / 100));
   
   const totalAfterDiscount = subTotal - discountAmount;
   const grandTotal = totalAfterDiscount + gstAmount;
   const balanceDue = grandTotal - Number(advancePayment);

   const cgst = !isInterState ? (gstAmount / 2) : 0;
   const sgst = !isInterState ? (gstAmount / 2) : 0;
   const igst = isInterState ? gstAmount : 0;

   const onSubmit = async (data) => {
      setApiError(null); // Clear previous errors

      if (data.items.length === 0) {
         setApiError("Please add at least one item to the invoice.");
         window.scrollTo({ top: 0, behavior: 'smooth' });
         return;
      }

      const payload = {
         ...data,
         gstEnabled,
         taxType,
         taxRate: Number(data.taxRate),
         discountPercentage: Number(data.discountPercentage),
         advancePayment: Number(data.advancePayment),
         items: data.items.map(item => ({
            ...item,
            quantity: Number(item.quantity),
            rate: Number(item.rate),
            gstRate: gstEnabled ? Number(item.gstRate) : 0,
            hsnCode: gstEnabled ? item.hsnCode : "",
            additionalDetails: item.additionalDetails
         }))
      };

      try {
         await api.put(`/invoices/${id}`, payload);
         queryClient.invalidateQueries({ queryKey: ['invoices'] });
         queryClient.invalidateQueries({ queryKey: ['dashboard'] });
         navigate(`/invoices/${id}`);
      } catch (e) {
         setApiError(e.response?.data?.message || e.message || "Failed to update invoice. Please try again.");
         window.scrollTo({ top: 0, behavior: 'smooth' });
      }
   };

   if (loading) return <Layout><div className="p-10 text-center text-gray-500">Loading Editor...</div></Layout>;

   return (
      <Layout>
         <datalist id="inventory-list">
            {inventoryItems.map(item => (
               <option key={item._id} value={item.itemName}>{item.sku ? `[${item.sku}]` : ''}</option>
            ))}
         </datalist>

         <div className="max-w-6xl mx-auto pb-20">

            {/* HEADER BAR */}
            <div className="flex justify-between items-center mb-6">
               <div className="flex items-center gap-4">
                  <Link to="/invoices" className="p-2 rounded-full hover:bg-gray-200 transition text-gray-600">
                     <ArrowLeft className="h-5 w-5" />
                  </Link>
                  <div>
                     <h1 className="text-2xl font-bold text-gray-800 flex items-center gap-2">
                        Edit Invoice
                        <span className="text-blue-600">#{invoiceNumber}</span>
                     </h1>
                     <p className="text-sm text-gray-500">Update details and pricing</p>
                  </div>
               </div>
               <button
                  onClick={handleSubmit(onSubmit)}
                  className="bg-blue-600 text-white px-6 py-2 rounded-lg font-bold hover:bg-blue-700 shadow-md flex items-center gap-2 transition transform hover:-translate-y-0.5"
               >
                  <Save className="h-4 w-4" /> Save Changes
               </button>
            </div>

            {/* GLOBAL API ERROR BANNER */}
            {apiError && (
               <div className="mb-6 bg-red-50 border-l-4 border-red-500 p-4 rounded-md flex items-start gap-3 shadow-sm">
                  <AlertCircle className="h-5 w-5 text-red-500 mt-0.5" />
                  <div>
                     <h3 className="text-sm font-bold text-red-800">Submission Error</h3>
                     <p className="text-sm text-red-700 mt-1">{apiError}</p>
                  </div>
               </div>
            )}

            {/* MISSING BUSINESS STATE WARNING */}
            {!loading && gstEnabled && !tenantState && (
               <div className="mb-6 bg-amber-50 border-l-4 border-amber-500 p-4 rounded-md flex items-start gap-3 shadow-sm">
                  <AlertCircle className="h-5 w-5 text-amber-500 mt-0.5" />
                  <div className="flex-1">
                     <h3 className="text-sm font-bold text-amber-800">Incomplete Business Profile</h3>
                     <p className="text-sm text-amber-700 mt-1">
                        Your **Business State** is not set in Settings. Automatic IGST/CGST detection will default to local tax.
                     </p>
                     <Link to="/settings" className="inline-block mt-2 text-xs font-bold text-amber-900 underline hover:no-underline">
                        Go to Settings to fix this
                     </Link>
                  </div>
               </div>
            )}

            <form noValidate onSubmit={handleSubmit(onSubmit)} className="space-y-6">

               {/* TOP SECTION: CLIENT & SETTINGS */}
               <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

                  {/* 1. CLIENT CARD */}
                  <div className="lg:col-span-2 bg-white p-6 rounded-xl shadow-sm border border-gray-200">
                     <div className="flex items-center gap-2 mb-4 text-gray-700 border-b pb-2">
                        <User className="h-4 w-4 text-blue-500" />
                        <h3 className="font-bold text-sm uppercase tracking-wide">Bill To</h3>
                     </div>

                     <div className="space-y-4">
                        <div>
                           <label className="block text-xs font-bold text-gray-500 mb-1">Search & Select Client</label>
                           <ClientAutocomplete clients={clients} onSelect={handleClientSelect} selectedClientId={watch('clientId')} />
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                           <div>
                              <label className="block text-xs font-bold text-gray-500 mb-1">Name <span className="text-red-500">*</span></label>
                              <input
                                 {...register("client.name", { required: "Client name is required" })}
                                 className={`w-full border p-2 rounded bg-gray-50 text-gray-700 focus:ring-2 outline-none ${errors.client?.name ? 'border-red-400 focus:ring-red-500' : 'focus:ring-blue-500'}`}
                              />
                              {errors.client?.name && <p className="text-red-500 text-xs mt-1 font-medium">{errors.client.name.message}</p>}
                           </div>
                           <div>
                              <label className="block text-xs font-bold text-gray-500 mb-1">Email</label>
                              <input
                                 {...register("client.email", {
                                    pattern: { value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i, message: "Invalid email address" }
                                 })}
                                 className={`w-full border p-2 rounded bg-gray-50 text-gray-700 focus:ring-2 outline-none ${errors.client?.email ? 'border-red-400 focus:ring-red-500' : 'focus:ring-blue-500'}`}
                              />
                              {errors.client?.email && <p className="text-red-500 text-xs mt-1 font-medium">{errors.client.email.message}</p>}
                           </div>
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                           <div>
                              <label className="block text-xs font-bold text-gray-500 mb-1">Billing Address</label>
                              <textarea {...register("client.address")} className="w-full border p-2 rounded bg-gray-50 text-gray-700 focus:ring-2 focus:ring-blue-500 outline-none" rows="2"></textarea>
                           </div>
                           <div>
                              <label className="block text-xs font-bold text-gray-500 mb-1">Details</label>
                              <div className="grid grid-cols-2 gap-2">
                                 <input {...register("client.gstin")} className="w-full border p-2 rounded bg-gray-50 text-gray-700 focus:ring-2 focus:ring-blue-500 outline-none uppercase text-xs" placeholder="GSTIN" />
                                 <select 
                                   {...register("client.state")} 
                                   className="w-full border p-2 rounded bg-gray-50 text-gray-700 focus:ring-2 focus:ring-blue-500 outline-none text-xs"
                                   onChange={(e) => {
                                       setValue("client.state", e.target.value);
                                       setValue("placeOfSupply", e.target.value);
                                   }}
                                 >
                                    <option value="">State</option>
                                    {INDIAN_STATES.map(s => <option key={s} value={s}>{s}</option>)}
                                 </select>
                              </div>
                           </div>
                        </div>
                     </div>
                  </div>

                  {/* 2. SETTINGS CARD */}
                  <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 h-full">
                     <div className="flex items-center gap-2 mb-4 text-gray-700 border-b pb-2">
                        <FileText className="h-4 w-4 text-purple-500" />
                        <h3 className="font-bold text-sm uppercase tracking-wide">Invoice Settings</h3>
                     </div>

                     <div className="space-y-4">
                        <div className="grid grid-cols-2 gap-3">
                           <div>
                              <label className="block text-xs font-bold text-gray-500 mb-1">Issued Date <span className="text-red-500">*</span></label>
                              <div className="relative">
                                 <Calendar className="absolute left-2 top-2.5 h-4 w-4 text-gray-400" />
                                 <input
                                    type="date"
                                    {...register("date", { required: "Required" })}
                                    className={`w-full border pl-8 p-2 rounded outline-none text-sm ${errors.date ? 'border-red-400 focus:ring-2 focus:ring-red-500' : 'focus:ring-2 focus:ring-purple-500'}`}
                                 />
                              </div>
                              {errors.date && <p className="text-red-500 text-xs mt-1 font-medium">{errors.date.message}</p>}
                           </div>
                           <div>
                              <label className="block text-xs font-bold text-gray-500 mb-1">Due Date <span className="text-red-500">*</span></label>
                              <div className="relative">
                                 <Calendar className="absolute left-2 top-2.5 h-4 w-4 text-gray-400" />
                                 <input
                                    type="date"
                                    {...register("dueDate", { required: "Required" })}
                                    min={invoiceDate}
                                    className={`w-full border pl-8 p-2 rounded outline-none text-sm ${errors.dueDate ? 'border-red-400 focus:ring-2 focus:ring-red-500' : 'focus:ring-2 focus:ring-purple-500'}`}
                                 />
                              </div>
                              {errors.dueDate && <p className="text-red-500 text-xs mt-1 font-medium">{errors.dueDate.message}</p>}
                           </div>
                        </div>

                        <div>
                           <label className="block text-xs font-bold text-gray-500 mb-1">Payment Status</label>
                           <select {...register("status")} className="w-full border p-2 rounded focus:ring-2 focus:ring-purple-500 outline-none text-sm bg-white">
                              <option value="Pending">Pending</option>
                              <option value="Paid">Paid</option>
                              <option value="Overdue">Overdue</option>
                           </select>
                        </div>

                        <div>
                           <label className="block text-xs font-bold text-gray-500 mb-1">Place of Supply <span className="text-red-500">*</span></label>
                           <select
                              {...register("placeOfSupply", { required: "Required" })}
                              className={`w-full border p-2 rounded outline-none text-sm bg-white ${errors.placeOfSupply ? 'border-red-400 focus:ring-2 focus:ring-red-500' : 'focus:ring-2 focus:ring-purple-500'}`}
                           >
                              <option value="">Select State</option>
                              {INDIAN_STATES.map(s => <option key={s} value={s}>{s}</option>)}
                           </select>
                           {errors.placeOfSupply && <p className="text-red-500 text-xs mt-1 font-medium">{errors.placeOfSupply.message}</p>}
                        </div>

                        {/* GST TOGGLE & TYPE */}
                        <div className="pt-2 border-t mt-2 space-y-3">
                           <div className="flex items-center justify-between bg-blue-50 p-3 rounded-lg border border-blue-100 cursor-pointer hover:bg-blue-100 transition" onClick={() => setGstEnabled(!gstEnabled)}>
                              <span className="text-sm font-bold text-blue-800 flex items-center gap-2">
                                 <CreditCard className="h-4 w-4" /> Enable GST
                              </span>
                              <div className={`w-10 h-6 flex items-center bg-gray-300 rounded-full p-1 duration-300 ease-in-out ${gstEnabled ? 'bg-blue-600' : ''}`}>
                                 <div className={`bg-white w-4 h-4 rounded-full shadow-md transform duration-300 ease-in-out ${gstEnabled ? 'translate-x-4' : ''}`}></div>
                              </div>
                           </div>
                           
                           {gstEnabled && (
                              <div className="flex gap-2">
                                 <button 
                                   type="button"
                                   onClick={() => setTaxType('exclusive')}
                                   className={`flex-1 py-2 text-[10px] font-black uppercase rounded-lg border-2 transition-all ${taxType === 'exclusive' ? 'bg-blue-600 border-blue-600 text-white shadow-md' : 'bg-white border-gray-200 text-gray-400'}`}
                                 >
                                   Tax Exclusive
                                 </button>
                                 <button 
                                   type="button"
                                   onClick={() => setTaxType('inclusive')}
                                   className={`flex-1 py-2 text-[10px] font-black uppercase rounded-lg border-2 transition-all ${taxType === 'inclusive' ? 'bg-blue-600 border-blue-600 text-white shadow-md' : 'bg-white border-gray-200 text-gray-400'}`}
                                 >
                                   Tax Inclusive
                                 </button>
                              </div>
                           )}
                        </div>
                     </div>
                  </div>
               </div>

               {/* --- MIDDLE SECTION: ITEMS TABLE (UPDATED LIKE CREATE INVOICE) --- */}
               <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                  <div className="bg-gray-50 px-6 py-3 border-b border-gray-200 flex justify-between items-center">
                     <h3 className="font-bold text-gray-700 uppercase text-xs tracking-wide">Line Items</h3>
                     <span className="text-xs text-gray-500">{fields.length} Items</span>
                  </div>

                  <div className="p-4">
                     {fields.map((field, index) => (
                        <Fragment key={field.id}>
                           <div className="grid grid-cols-1 md:grid-cols-12 gap-4 mb-4 pb-4 border-b border-gray-100 items-start">

                           {/* 1. Item Description Area (Dynamic Col Span based on GST) */}
                           <div className={`space-y-2 ${gstEnabled ? 'md:col-span-4' : 'md:col-span-6'}`}>
                              <div>
                                 <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1 block">Item Name / Title <span className="text-red-500">*</span></label>
                                 <input
                                    {...register(`items.${index}.description`, { required: "Item description is required" })}
                                    list="inventory-list"
                                    onChange={(e) => {
                                       setValue(`items.${index}.description`, e.target.value);
                                       const selectedItem = inventoryItems.find(i => i.itemName === e.target.value);
                                       if (selectedItem) {
                                           setValue(`items.${index}.inventoryId`, selectedItem._id);
                                           setValue(`items.${index}.rate`, selectedItem.unitPrice);
                                           setValue(`items.${index}.availableStock`, selectedItem.currentStock);
                                           if (selectedItem.description) {
                                               setValue(`items.${index}.additionalDetails`, selectedItem.description);
                                           }
                                           if (gstEnabled && selectedItem.sku) {
                                               setValue(`items.${index}.hsnCode`, selectedItem.sku);
                                           }
                                       } else {
                                           setValue(`items.${index}.inventoryId`, null);
                                           setValue(`items.${index}.availableStock`, null);
                                       }
                                    }}
                                    className={`w-full border rounded p-2 font-bold text-gray-800 placeholder-gray-400 outline-none ${errors.items?.[index]?.description ? 'border-red-400 focus:ring-2 focus:ring-red-500' : 'border-gray-300 focus:ring-2 focus:ring-blue-500'}`}
                                    placeholder="e.g. Website Design"
                                 />
                                 {errors.items?.[index]?.description && <p className="text-red-500 text-[10px] mt-1 font-medium">{errors.items[index].description.message}</p>}
                              </div>
                              <div>
                                 <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1 block">Detailed Description</label>
                                 <textarea
                                    {...register(`items.${index}.additionalDetails`)}
                                    className="w-full border border-gray-300 rounded p-2 text-sm text-gray-600 placeholder-gray-400 focus:ring-2 focus:ring-blue-500 outline-none h-[42px] resize-none"
                                    placeholder="Optional details..."
                                 />
                              </div>
                           </div>

                           {/* 2. HSN CODE (Conditional: Only shows if GST is Enabled) */}
                           {gstEnabled && (
                              <div className="md:col-span-2">
                                 <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1 block text-center">HSN/SAC</label>
                                 <input
                                    type="text"
                                    {...register(`items.${index}.hsnCode`)}
                                    className="w-full border border-gray-300 p-2 rounded text-center focus:ring-2 focus:ring-blue-500 outline-none text-sm font-mono"
                                    placeholder="HSN"
                                 />
                              </div>
                           )}

                           {/* 3. Quantity (col-span-2) */}
                           <div className="md:col-span-2">
                              <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1 block text-center">Qty <span className="text-red-500">*</span></label>
                              <input
                                 type="number"
                                 {...register(`items.${index}.quantity`, {
                                    required: "Required",
                                    min: { value: 0.1, message: "> 0" },
                                    validate: (value) => {
                                       const stock = items?.[index]?.availableStock;
                                       if (stock !== undefined && stock !== null && Number(value) > stock) {
                                          return `Max: ${stock}`;
                                       }
                                       return true;
                                    }
                                 })}
                                 className={`w-full border p-2 rounded text-center outline-none font-medium ${errors.items?.[index]?.quantity ? 'border-red-400 focus:ring-2 focus:ring-red-500' : 'border-gray-300 focus:ring-2 focus:ring-blue-500'}`}
                                 step="any"
                              />
                              {items?.[index]?.availableStock !== undefined && items?.[index]?.availableStock !== null && (
                                  <div className="text-[9px] text-center text-gray-500 mt-1 font-bold">
                                      In Stock: {items[index].availableStock}
                                  </div>
                              )}
                              {errors.items?.[index]?.quantity && <p className="text-red-500 text-[10px] mt-1 text-center font-medium">{errors.items[index].quantity.message}</p>}
                           </div>

                           {/* 4. Rate (col-span-2) */}
                           <div className="md:col-span-2">
                              <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1 block text-right">Rate <span className="text-red-500">*</span></label>
                              <input
                                 type="number"
                                 step="0.01"
                                 {...register(`items.${index}.rate`, {
                                    required: "Required",
                                    min: { value: 0, message: "Invalid" }
                                 })}
                                 className={`w-full border p-2 rounded text-right outline-none font-medium ${errors.items?.[index]?.rate ? 'border-red-400 focus:ring-2 focus:ring-red-500' : 'border-gray-300 focus:ring-2 focus:ring-blue-500'}`}
                              />
                              {errors.items?.[index]?.rate && <p className="text-red-500 text-[10px] mt-1 text-right font-medium">{errors.items[index].rate.message}</p>}
                           </div>

                           {/* 5. Total & Delete (col-span-2) */}
                           <div className="md:col-span-2 flex flex-col justify-between h-full items-end">
                              <div className="text-right w-full">
                                 <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1 block">Amount</label>
                                 <div className="w-full bg-gray-50 border border-transparent p-2 rounded text-right">
                                    <span className="text-lg font-bold text-gray-800">
                                       {((Number(items?.[index]?.quantity) || 0) * (Number(items?.[index]?.rate) || 0)).toFixed(2)}
                                    </span>
                                 </div>
                              </div>
                              <button type="button" onClick={() => remove(index)} className="text-red-400 hover:text-red-600 transition flex items-center gap-1 text-xs font-bold mt-2 bg-red-50 hover:bg-red-100 px-2 py-1 rounded">
                                 <Trash2 className="h-3 w-3" /> Remove
                              </button>
                           </div>
                        </div>
                        
                        {gstEnabled && (
                           <div className="grid grid-cols-1 md:grid-cols-4 gap-4 px-2 py-2 mb-4 bg-blue-50/30 rounded-lg border border-blue-100/50">
                              <div className="md:col-span-1">
                                 <label className="text-[9px] font-black text-blue-400 uppercase tracking-tighter mb-1 block">GST Rate (%)</label>
                                 <select {...register(`items.${index}.gstRate`)} className="w-full bg-white border border-blue-100 p-1 rounded text-xs font-bold text-blue-700 outline-none">
                                    <option value="0">0% (Exempt)</option>
                                    <option value="5">5%</option>
                                    <option value="12">12%</option>
                                    <option value="18">18%</option>
                                    <option value="28">28%</option>
                                 </select>
                              </div>
                              <div className="md:col-span-2 text-right flex flex-col justify-center">
                                 <span className="text-[9px] font-black text-gray-400 uppercase tracking-tighter">Taxable Value</span>
                                 <span className="text-xs font-bold text-gray-600">₹{processedItems[index]?.taxable.toFixed(2)}</span>
                              </div>
                              <div className="md:col-span-1 text-right flex flex-col justify-center">
                                 <span className="text-[9px] font-black text-blue-400 uppercase tracking-tighter">Tax Amount</span>
                                 <span className="text-xs font-black text-blue-600">₹{processedItems[index]?.tax.toFixed(2)}</span>
                              </div>
                           </div>
                        )}
                     </Fragment>
                  ))}

                     <button
                        type="button"
                        onClick={() => append({ description: "", additionalDetails: "", hsnCode: "", gstRate: 18, quantity: 1, rate: 0, inventoryId: null, availableStock: null })}
                        className="mt-2 text-blue-600 font-bold text-sm hover:underline flex items-center gap-1"
                     >
                        <Plus className="h-4 w-4" /> Add New Item Line
                     </button>
                  </div>
               </div>

               {/* BOTTOM SECTION: SUMMARY & FOOTER */}
               <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                  {/* LEFT: Terms */}
                  <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
                     <label className="block text-xs font-bold text-gray-500 uppercase mb-2">Terms & Conditions</label>
                     <textarea {...register("terms")} className="w-full border p-3 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 outline-none h-32 resize-none" placeholder="Enter payment terms, delivery notes, etc."></textarea>
                  </div>

                  {/* RIGHT: Financials */}
                  <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
                     <div className="space-y-3">
                        <div className="flex justify-between text-gray-600">
                           <span>Subtotal</span>
                           <span className="font-medium">₹{subTotal.toFixed(2)}</span>
                        </div>

                        {/* --- DISCOUNT FIELD --- */}
                        <div className="flex justify-between items-center text-gray-600">
                           <span className="flex items-center gap-2 text-sm">
                              Discount (%)
                              <input
                                 type="number"
                                 {...register("discountPercentage", { min: 0, max: 100 })}
                                 className="w-16 border p-1 rounded text-right text-xs focus:ring-2 focus:ring-blue-500 outline-none"
                              />
                           </span>
                           <span className="text-red-500 font-medium">- ₹{discountAmount.toFixed(2)}</span>
                        </div>

                        {gstEnabled && (
                           <div className="bg-blue-50 p-4 rounded-xl border border-blue-100 space-y-2 mt-4">
                              <div className="flex justify-between items-center border-b border-blue-200 pb-1 mb-2">
                                 <h4 className="text-[10px] font-black text-blue-800 uppercase tracking-widest">GST Breakdown</h4>
                                 <span className="text-[9px] font-bold bg-blue-600 text-white px-1.5 py-0.5 rounded">
                                    {isInterState ? 'INTER-STATE (IGST)' : 'INTRA-STATE (CGST+SGST)'}
                                 </span>
                              </div>
                              {isInterState ? (
                                 <div className="flex justify-between text-sm">
                                    <span className="text-blue-600 font-bold">IGST</span>
                                    <span className="font-black text-blue-800">₹{igst.toFixed(2)}</span>
                                 </div>
                              ) : (
                                 <>
                                    <div className="flex justify-between text-sm">
                                       <span className="text-blue-600 font-bold">CGST ({(taxRate / 2)}%)</span>
                                       <span className="font-black text-blue-800">₹{cgst.toFixed(2)}</span>
                                    </div>
                                    <div className="flex justify-between text-sm">
                                       <span className="text-blue-600 font-bold">SGST ({(taxRate / 2)}%)</span>
                                       <span className="font-black text-blue-800">₹{sgst.toFixed(2)}</span>
                                    </div>
                                 </>
                              )}
                              <div className="flex justify-between pt-1 border-t border-blue-200 mt-1">
                                 <span className="text-xs font-black text-blue-800 uppercase">Total GST</span>
                                 <span className="text-sm font-black text-blue-900 underline decoration-blue-300 underline-offset-4">₹{gstAmount.toFixed(2)}</span>
                              </div>
                           </div>
                        )}

                        <div className="flex justify-between text-gray-600 pt-2">
                           <span className="flex items-center gap-2 text-sm">
                              Advance Paid
                              <input
                                 type="number"
                                 {...register("advancePayment", { min: 0 })}
                                 className="w-24 border p-1 rounded text-right text-xs focus:ring-2 focus:ring-blue-500 outline-none"
                              />
                           </span>
                           <span className="text-green-600 font-medium">- ₹{Number(advancePayment).toFixed(2)}</span>
                        </div>

                        <div className="border-t pt-4 mt-2 flex justify-between items-end">
                           <div className="text-right w-full">
                              <p className="text-xs text-gray-500 uppercase mb-1">Balance Due</p>
                              <p className="text-3xl font-extrabold text-gray-900">₹{balanceDue.toFixed(2)}</p>
                              <p className="text-xs text-gray-400 mt-1">Total Amount: ₹{grandTotal.toFixed(2)}</p>
                           </div>
                        </div>
                     </div>
                  </div>
               </div>

            </form>
         </div>
      </Layout>
   );
};

export default EditInvoice;