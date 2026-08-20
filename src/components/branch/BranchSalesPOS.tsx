import React, { useState, useMemo, useRef } from 'react';
import { useData } from '../../context/DataContext';
import { Product } from '../../types';
import {
  ShoppingCart,
  CheckCircle2,
  AlertCircle,
  Receipt,
  Plus,
  Minus,
  Trash2,
  Printer,
  Search,
  RefreshCw,
  Download,
  Upload,
  CreditCard,
  Banknote,
  Smartphone,
  Tag,
  User,
  SlidersHorizontal,
  X,
  FileSpreadsheet,
  Check,
  Zap,
  Info,
  ChevronRight,
} from 'lucide-react';

interface CartItem {
  product: Product;
  quantity: number;
}

export const BranchSalesPOS: React.FC = () => {
  const {
    products,
    currentBranch,
    recordMultiItemSale,
    importZobazeSalesBatch,
    getInventoryForBranch,
    getSalesForBranch,
    themeMode,
    currentUser,
  } = useData();

  if (!currentBranch) return null;

  const branchId = currentBranch.id;
  const inventory = getInventoryForBranch(branchId);
  const branchSales = getSalesForBranch(branchId);

  const isDark = themeMode === 'dark';

  // Navigation tabs inside POS
  const [activeTab, setActiveTab] = useState<'register' | 'zobazeSync' | 'receipts'>('register');

  // Register Search & Filter
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  // Cart State
  const [cart, setCart] = useState<CartItem[]>([]);
  const [customerName, setCustomerName] = useState('');
  const [discountType, setDiscountType] = useState<'none' | 'pwd_senior' | 'promo10' | 'custom'>('none');
  const [customDiscountValue, setCustomDiscountValue] = useState<number>(0);

  // Payment Checkout Modal
  const [isCheckoutOpen, setIsCheckoutOpen] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState<'Cash' | 'GCash' | 'Maya' | 'Card' | 'Zobaze POS'>('Cash');
  const [amountTendered, setAmountTendered] = useState<string>('');
  const [referenceNumber, setReferenceNumber] = useState('');

  // Active Receipt Modal
  const [activeReceipt, setActiveReceipt] = useState<{
    receiptNumber: string;
    items: { flavor: string; qty: number; unitPrice: number; total: number }[];
    subtotal: number;
    discountAmount: number;
    discountType: string;
    totalAmount: number;
    paymentMethod: string;
    amountTendered?: number;
    change?: number;
    date: string;
    cashierName?: string;
    customerName?: string;
  } | null>(null);

  // Notifications
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // Zobaze Import State
  const [csvText, setCsvText] = useState('');
  const [importResult, setImportResult] = useState<{ successCount: number; errors: string[] } | null>(null);
  const [isImporting, setIsImporting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Calculate stock lookup map
  const stockMap = useMemo(() => {
    const map: Record<string, number> = {};
    inventory.forEach((inv) => {
      map[inv.productId] = inv.stock;
    });
    return map;
  }, [inventory]);

  // Filtered Products
  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const matchesSearch =
        p.flavor.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.name.toLowerCase().includes(searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      const stock = stockMap[p.id] ?? 0;
      if (selectedCategory === 'in_stock') return stock > 0;
      if (selectedCategory === 'low_stock') return stock > 0 && stock <= 10;
      return true;
    });
  }, [products, searchQuery, selectedCategory, stockMap]);

  // Cart Calculations
  const grossSubtotal = useMemo(() => {
    return cart.reduce((sum, item) => sum + item.product.price * item.quantity, 0);
  }, [cart]);

  const discountAmount = useMemo(() => {
    if (discountType === 'pwd_senior') {
      return Math.round(grossSubtotal * 0.2); // 20% Senior/PWD statutory discount
    }
    if (discountType === 'promo10') {
      return Math.round(grossSubtotal * 0.1); // 10% Special promo
    }
    if (discountType === 'custom') {
      return Math.min(grossSubtotal, customDiscountValue);
    }
    return 0;
  }, [grossSubtotal, discountType, customDiscountValue]);

  const netPayable = Math.max(0, grossSubtotal - discountAmount);
  const totalCartUnits = cart.reduce((sum, item) => sum + item.quantity, 0);

  const tenderedNum = parseFloat(amountTendered) || 0;
  const changeDue = paymentMethod === 'Cash' ? Math.max(0, tenderedNum - netPayable) : 0;

  // Cart Operations
  const addToCart = (product: Product) => {
    const available = stockMap[product.id] ?? 0;
    const existing = cart.find((i) => i.product.id === product.id);
    const currentQty = existing ? existing.quantity : 0;

    if (currentQty + 1 > available) {
      setErrorMsg(`Cannot add more ${product.flavor}. Max branch stock available is ${available} units.`);
      setTimeout(() => setErrorMsg(null), 4000);
      return;
    }

    if (existing) {
      setCart(cart.map((i) => (i.product.id === product.id ? { ...i, quantity: i.quantity + 1 } : i)));
    } else {
      setCart([...cart, { product, quantity: 1 }]);
    }
    setErrorMsg(null);
  };

  const updateQuantity = (productId: string, delta: number) => {
    const item = cart.find((i) => i.product.id === productId);
    if (!item) return;

    const available = stockMap[productId] ?? 0;
    const newQty = item.quantity + delta;

    if (newQty <= 0) {
      removeFromCart(productId);
      return;
    }

    if (newQty > available) {
      setErrorMsg(`Cannot increase. Only ${available} units in branch inventory.`);
      setTimeout(() => setErrorMsg(null), 4000);
      return;
    }

    setCart(cart.map((i) => (i.product.id === productId ? { ...i, quantity: newQty } : i)));
  };

  const removeFromCart = (productId: string) => {
    setCart(cart.filter((i) => i.product.id !== productId));
  };

  const clearCart = () => {
    setCart([]);
    setCustomerName('');
    setDiscountType('none');
    setCustomDiscountValue(0);
    setAmountTendered('');
    setReferenceNumber('');
  };

  // Checkout Execution
  const handleOpenCheckout = () => {
    if (cart.length === 0) {
      setErrorMsg('Cart is empty. Add marshmallow flavors before checking out.');
      return;
    }
    setAmountTendered(netPayable.toString());
    setIsCheckoutOpen(true);
  };

  const handleFinalizeTransaction = () => {
    if (paymentMethod === 'Cash' && tenderedNum < netPayable) {
      setErrorMsg(`Amount tendered (₱${tenderedNum}) is less than total payable (₱${netPayable}).`);
      return;
    }

    try {
      const receiptNumber = `ZB-REC-${new Date().getFullYear()}${String(new Date().getMonth() + 1).padStart(2, '0')}-${Math.floor(1000 + Math.random() * 9000)}`;

      const itemsPayload = cart.map((i) => ({
        productId: i.product.id,
        quantity: i.quantity,
        unitPrice: i.product.price,
      }));

      recordMultiItemSale({
        items: itemsPayload,
        paymentMethod: paymentMethod === 'Zobaze POS' ? 'Zobaze POS' : paymentMethod,
        amountTendered: paymentMethod === 'Cash' ? tenderedNum : netPayable,
        change: paymentMethod === 'Cash' ? changeDue : 0,
        discountAmount,
        discountType: discountType !== 'none' ? discountType.toUpperCase() : undefined,
        customerName: customerName || undefined,
        receiptNumber,
        source: paymentMethod === 'Zobaze POS' ? 'Zobaze POS Sync' : 'VertexIS POS',
      });

      // Prepare receipt data
      const receiptData = {
        receiptNumber,
        items: cart.map((i) => ({
          flavor: i.product.flavor,
          qty: i.quantity,
          unitPrice: i.product.price,
          total: i.quantity * i.product.price,
        })),
        subtotal: grossSubtotal,
        discountAmount,
        discountType: discountType === 'pwd_senior' ? 'Senior / PWD (20%)' : discountType === 'promo10' ? 'Promo 10%' : discountType === 'custom' ? 'Custom Discount' : 'None',
        totalAmount: netPayable,
        paymentMethod,
        amountTendered: paymentMethod === 'Cash' ? tenderedNum : netPayable,
        change: paymentMethod === 'Cash' ? changeDue : 0,
        date: new Date().toLocaleString('en-US', { dateStyle: 'medium', timeStyle: 'short' }),
        cashierName: currentUser?.name || 'Store Cashier',
        customerName: customerName || undefined,
      };

      setIsCheckoutOpen(false);
      clearCart();
      setActiveReceipt(receiptData);
      setSuccessMsg(`Transaction #${receiptNumber} processed! Stock updated in real-time.`);
      setTimeout(() => setSuccessMsg(null), 5000);
    } catch (err: any) {
      setErrorMsg(err.message || 'Failed to finalize transaction');
    }
  };

  // Zobaze Import Process
  const handleImportCsv = () => {
    if (!csvText.trim()) {
      setErrorMsg('Please paste Zobaze sales CSV text or choose a file.');
      return;
    }
    setIsImporting(true);
    setErrorMsg(null);
    setImportResult(null);

    try {
      const lines = csvText.trim().split('\n');
      const parsedRows: Array<{ flavor: string; quantity: number; total: number; date?: string; paymentMethod?: string; receipt?: string }> = [];

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line || i === 0 && line.toLowerCase().includes('flavor')) continue; // Skip header

        const parts = line.split(',').map((p) => p.trim().replace(/^["']|["']$/g, ''));
        if (parts.length >= 2) {
          const flavor = parts[0];
          const quantity = parseInt(parts[1], 10) || 1;
          const total = parseFloat(parts[2]) || 0;
          const paymentMethod = parts[3] || 'Zobaze POS';
          const date = parts[4] || new Date().toISOString();
          const receipt = parts[5] || `ZB-IMP-${Date.now().toString().slice(-4)}-${i}`;

          parsedRows.push({ flavor, quantity, total, paymentMethod, date, receipt });
        }
      }

      if (parsedRows.length === 0) {
        throw new Error('No valid sales rows found in provided CSV data.');
      }

      const result = importZobazeSalesBatch(parsedRows);
      setImportResult(result);
      if (result.successCount > 0) {
        setSuccessMsg(`Successfully imported ${result.successCount} sales from Zobaze POS!`);
        setCsvText('');
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Failed to parse Zobaze CSV data');
    } finally {
      setIsImporting(false);
    }
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const text = event.target?.result as string;
      setCsvText(text);
    };
    reader.readAsText(file);
  };

  // Zobaze Catalog Export
  const exportZobazeCatalog = () => {
    const headers = ['Item Name', 'Category', 'Price', 'Stock', 'SKU', 'Barcode', 'Description'];
    const rows = products.map((p) => [
      `"${p.flavor} - Marsh Bites"`,
      '"Artisanal Marshmallows"',
      p.price.toFixed(2),
      stockMap[p.id] ?? 0,
      `"MB-${p.id.toUpperCase()}"`,
      `"48000${p.id.replace(/\D/g, '').padEnd(6, '0')}"`,
      `"Handcrafted in Bicol - ${p.name}"`,
    ]);

    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows.map((e) => e.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `zobaze_catalog_${currentBranch.id}_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // Zobaze Sales Export
  const exportZobazeSales = () => {
    const headers = ['Receipt #', 'Date & Time', 'Product Name', 'Qty', 'Total (PHP)', 'Payment Method', 'Cashier', 'Customer'];
    const rows = branchSales.map((s) => [
      `"${s.receiptPath || s.id}"`,
      `"${new Date(s.date).toLocaleString('en-US')}"`,
      `"${s.productName}"`,
      s.quantity,
      s.total.toFixed(2),
      `"${s.paymentMethod || 'Cash'}"`,
      `"${s.cashierName || 'Branch Staff'}"`,
      `"${s.customerName || 'Walk-in Customer'}"`,
    ]);

    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows.map((e) => e.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `zobaze_sales_ledger_${currentBranch.id}_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // Shift Totals
  const todaySales = branchSales.filter((s) => new Date(s.date).toDateString() === new Date().toDateString());
  const todayRevenue = todaySales.reduce((sum, s) => sum + s.total, 0);
  const todayUnits = todaySales.reduce((sum, s) => sum + s.quantity, 0);

  return (
    <div className="space-y-6">
      {/* Top Banner & Tab Navigation */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center space-x-2.5">
            <h1 className="text-2xl font-black tracking-tight">Point of Sale (POS)</h1>
            <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-[#F37021]/15 text-[#F37021] border border-[#F37021]/30">
              ZOBAZE POS CONNECTED
            </span>
          </div>
          <p className="text-xs text-neutral-500 font-medium mt-0.5">
            High-speed touch register terminal, multi-item checkout, and direct Zobaze POS data synchronization.
          </p>
        </div>

        {/* View Switcher Tabs */}
        <div className="flex items-center p-1 rounded-2xl bg-neutral-100 dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-700">
          <button
            type="button"
            id="tab-pos-register"
            onClick={() => setActiveTab('register')}
            className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'register'
                ? 'bg-white dark:bg-neutral-700 text-[#0c5077] dark:text-[#80C7F2] shadow-xs'
                : 'text-neutral-500 hover:text-neutral-900 dark:hover:text-white'
            }`}
          >
            <ShoppingCart className="w-4 h-4" />
            <span>POS Register</span>
          </button>
          <button
            type="button"
            id="tab-zobaze-sync"
            onClick={() => setActiveTab('zobazeSync')}
            className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'zobazeSync'
                ? 'bg-white dark:bg-neutral-700 text-[#F37021] shadow-xs'
                : 'text-neutral-500 hover:text-neutral-900 dark:hover:text-white'
            }`}
          >
            <RefreshCw className="w-4 h-4" />
            <span>Zobaze POS Sync</span>
          </button>
          <button
            type="button"
            id="tab-pos-receipts"
            onClick={() => setActiveTab('receipts')}
            className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'receipts'
                ? 'bg-white dark:bg-neutral-700 text-emerald-600 dark:text-emerald-400 shadow-xs'
                : 'text-neutral-500 hover:text-neutral-900 dark:hover:text-white'
            }`}
          >
            <Receipt className="w-4 h-4" />
            <span>Shift Receipts ({todaySales.length})</span>
          </button>
        </div>
      </div>

      {/* Global Alerts */}
      {errorMsg && (
        <div className="p-4 rounded-2xl bg-red-500/10 border border-red-500/30 text-red-600 dark:text-red-400 text-xs font-medium flex items-center justify-between">
          <div className="flex items-center space-x-2.5">
            <AlertCircle className="w-4 h-4 flex-shrink-0" />
            <span>{errorMsg}</span>
          </div>
          <button type="button" onClick={() => setErrorMsg(null)} className="text-red-500 hover:opacity-80">
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {successMsg && (
        <div className="p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-600 dark:text-emerald-400 text-xs font-bold flex items-center justify-between">
          <div className="flex items-center space-x-2.5">
            <CheckCircle2 className="w-4 h-4 flex-shrink-0" />
            <span>{successMsg}</span>
          </div>
          <button type="button" onClick={() => setSuccessMsg(null)} className="text-emerald-500 hover:opacity-80">
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* TAB 1: POS REGISTER TERMINAL */}
      {activeTab === 'register' && (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          {/* Left Column: Product Grid & Quick Filters (7 cols) */}
          <div className="lg:col-span-7 space-y-4">
            {/* Search & Category Filter Bar */}
            <div className={`p-4 rounded-3xl border ${isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-[#80C7F2]/20 shadow-xs'}`}>
              <div className="flex flex-col sm:flex-row gap-3">
                <div className="relative flex-1">
                  <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-neutral-400" />
                  <input
                    type="text"
                    id="pos-search-input"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Search flavor (Ube, Matcha, Mango, Biscoff)..."
                    className="w-full pl-10 pr-4 py-2.5 rounded-2xl border border-neutral-200 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-900 text-xs focus:outline-none focus:ring-2 focus:ring-[#80C7F2]"
                  />
                  {searchQuery && (
                    <button
                      type="button"
                      onClick={() => setSearchQuery('')}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-neutral-400 hover:text-neutral-600"
                    >
                      <X className="w-3.5 h-3.5" />
                    </button>
                  )}
                </div>

                <div className="flex items-center space-x-1.5 overflow-x-auto pb-1 sm:pb-0">
                  <button
                    type="button"
                    onClick={() => setSelectedCategory('all')}
                    className={`px-3 py-2 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                      selectedCategory === 'all'
                        ? 'bg-[#80C7F2] text-white'
                        : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-600 dark:text-neutral-400'
                    }`}
                  >
                    All Flavors ({products.length})
                  </button>
                  <button
                    type="button"
                    onClick={() => setSelectedCategory('in_stock')}
                    className={`px-3 py-2 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                      selectedCategory === 'in_stock'
                        ? 'bg-emerald-600 text-white'
                        : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-600 dark:text-neutral-400'
                    }`}
                  >
                    In Stock
                  </button>
                  <button
                    type="button"
                    onClick={() => setSelectedCategory('low_stock')}
                    className={`px-3 py-2 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                      selectedCategory === 'low_stock'
                        ? 'bg-amber-600 text-white'
                        : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-600 dark:text-neutral-400'
                    }`}
                  >
                    Low Stock
                  </button>
                </div>
              </div>
            </div>

            {/* Product Cards Grid */}
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3.5">
              {filteredProducts.map((product) => {
                const stock = stockMap[product.id] ?? 0;
                const isOutOfStock = stock === 0;
                const inCart = cart.find((i) => i.product.id === product.id);

                return (
                  <button
                    key={product.id}
                    type="button"
                    id={`pos-product-${product.id}`}
                    disabled={isOutOfStock}
                    onClick={() => addToCart(product)}
                    className={`group relative p-4 rounded-3xl border text-left transition-all flex flex-col justify-between h-44 ${
                      inCart
                        ? 'border-[#80C7F2] bg-[#80C7F2]/10 dark:bg-[#80C7F2]/15 shadow-sm'
                        : isOutOfStock
                        ? 'opacity-40 border-neutral-200 dark:border-neutral-800 bg-neutral-100 dark:bg-neutral-900 cursor-not-allowed'
                        : isDark
                        ? 'bg-[#161616] border-neutral-800 hover:border-[#80C7F2] hover:bg-neutral-800/60'
                        : 'bg-white border-neutral-200/90 hover:border-[#80C7F2] hover:shadow-md'
                    }`}
                  >
                    {/* In Cart Badge */}
                    {inCart && (
                      <div className="absolute top-3 right-3 px-2 py-0.5 rounded-full bg-[#80C7F2] text-white text-[10px] font-black shadow-xs">
                        {inCart.quantity} in cart
                      </div>
                    )}

                    <div>
                      <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[#80C7F2]/20 to-[#F37021]/20 flex items-center justify-center text-sm font-black text-[#F37021] mb-2.5">
                        {product.flavor.slice(0, 2).toUpperCase()}
                      </div>
                      <h3 className="font-bold text-sm text-neutral-900 dark:text-white leading-tight line-clamp-1">
                        {product.flavor}
                      </h3>
                      <p className="text-[11px] text-neutral-400 mt-0.5 line-clamp-1">
                        {product.name}
                      </p>
                    </div>

                    <div className="pt-2 border-t border-neutral-200/60 dark:border-neutral-800 flex items-center justify-between">
                      <span className="font-black text-sm text-[#F37021]">
                        ₱{product.price}
                      </span>
                      <span
                        className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                          stock === 0
                            ? 'bg-red-500/15 text-red-500'
                            : stock <= 10
                            ? 'bg-amber-500/15 text-amber-600 dark:text-amber-400'
                            : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-500'
                        }`}
                      >
                        {stock} left
                      </span>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Right Column: Interactive Cart & Checkout Ledger (5 cols) */}
          <div className="lg:col-span-5 space-y-4">
            <div className={`p-6 rounded-3xl border flex flex-col ${isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-[#80C7F2]/20 shadow-xs'}`}>
              <div className="flex items-center justify-between pb-4 border-b border-neutral-200 dark:border-neutral-800">
                <div className="flex items-center space-x-2">
                  <ShoppingCart className="w-5 h-5 text-[#F37021]" />
                  <h2 className="text-base font-bold">Current Order Cart</h2>
                  <span className="text-xs font-bold px-2 py-0.5 rounded-full bg-neutral-100 dark:bg-neutral-800 text-neutral-500">
                    {totalCartUnits} pcs
                  </span>
                </div>
                {cart.length > 0 && (
                  <button
                    type="button"
                    onClick={clearCart}
                    className="text-xs font-semibold text-red-500 hover:text-red-600 flex items-center space-x-1"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                    <span>Clear</span>
                  </button>
                )}
              </div>

              {/* Cart Items List */}
              <div className="py-4 space-y-3 max-h-72 overflow-y-auto pr-1">
                {cart.length === 0 ? (
                  <div className="py-12 text-center text-neutral-400 space-y-2">
                    <ShoppingCart className="w-10 h-10 mx-auto opacity-30 stroke-1" />
                    <p className="text-xs font-medium">Cart is empty.</p>
                    <p className="text-[11px] text-neutral-500">
                      Tap flavors on the left to add items to this order.
                    </p>
                  </div>
                ) : (
                  cart.map((item) => {
                    const lineTotal = item.product.price * item.quantity;
                    return (
                      <div
                        key={item.product.id}
                        className="p-3 rounded-2xl bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 flex items-center justify-between gap-2"
                      >
                        <div className="min-w-0 flex-1">
                          <p className="font-bold text-xs truncate text-neutral-900 dark:text-white">
                            {item.product.flavor}
                          </p>
                          <p className="text-[10px] text-neutral-400">
                            ₱{item.product.price} × {item.quantity} = <strong className="text-neutral-700 dark:text-neutral-200">₱{lineTotal}</strong>
                          </p>
                        </div>

                        <div className="flex items-center space-x-2">
                          <button
                            type="button"
                            onClick={() => updateQuantity(item.product.id, -1)}
                            className="w-7 h-7 rounded-xl border border-neutral-300 dark:border-neutral-700 flex items-center justify-center font-bold text-xs hover:bg-neutral-200 dark:hover:bg-neutral-800"
                          >
                            <Minus className="w-3 h-3" />
                          </button>
                          <span className="w-6 text-center font-black text-xs">
                            {item.quantity}
                          </span>
                          <button
                            type="button"
                            onClick={() => updateQuantity(item.product.id, 1)}
                            className="w-7 h-7 rounded-xl border border-neutral-300 dark:border-neutral-700 flex items-center justify-center font-bold text-xs hover:bg-neutral-200 dark:hover:bg-neutral-800"
                          >
                            <Plus className="w-3 h-3" />
                          </button>
                          <button
                            type="button"
                            onClick={() => removeFromCart(item.product.id)}
                            className="text-neutral-400 hover:text-red-500 p-1"
                          >
                            <X className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>

              {/* Customer & Discount Controls */}
              {cart.length > 0 && (
                <div className="pt-3 border-t border-neutral-200 dark:border-neutral-800 space-y-3 text-xs">
                  <div>
                    <label className="block text-[11px] font-bold text-neutral-500 uppercase tracking-wider mb-1">
                      Customer Name / Note (Optional):
                    </label>
                    <div className="relative">
                      <User className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400" />
                      <input
                        type="text"
                        value={customerName}
                        onChange={(e) => setCustomerName(e.target.value)}
                        placeholder="e.g. Maria Santos / Table 4"
                        className="w-full pl-9 pr-3 py-2 rounded-xl border border-neutral-200 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-900 text-xs focus:outline-none focus:ring-2 focus:ring-[#80C7F2]"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-[11px] font-bold text-neutral-500 uppercase tracking-wider mb-1">
                      Discount / Promo:
                    </label>
                    <div className="grid grid-cols-3 gap-1.5">
                      <button
                        type="button"
                        onClick={() => setDiscountType('none')}
                        className={`py-1.5 px-2 rounded-xl text-[11px] font-bold border transition-all ${
                          discountType === 'none'
                            ? 'bg-[#80C7F2]/20 border-[#80C7F2] text-[#0c5077] dark:text-[#80C7F2]'
                            : 'border-neutral-200 dark:border-neutral-800 text-neutral-500'
                        }`}
                      >
                        None
                      </button>
                      <button
                        type="button"
                        onClick={() => setDiscountType('pwd_senior')}
                        className={`py-1.5 px-2 rounded-xl text-[11px] font-bold border transition-all ${
                          discountType === 'pwd_senior'
                            ? 'bg-[#80C7F2]/20 border-[#80C7F2] text-[#0c5077] dark:text-[#80C7F2]'
                            : 'border-neutral-200 dark:border-neutral-800 text-neutral-500'
                        }`}
                      >
                        Senior/PWD 20%
                      </button>
                      <button
                        type="button"
                        onClick={() => setDiscountType('promo10')}
                        className={`py-1.5 px-2 rounded-xl text-[11px] font-bold border transition-all ${
                          discountType === 'promo10'
                            ? 'bg-[#80C7F2]/20 border-[#80C7F2] text-[#0c5077] dark:text-[#80C7F2]'
                            : 'border-neutral-200 dark:border-neutral-800 text-neutral-500'
                        }`}
                      >
                        Promo 10%
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {/* Price Calculation Summary */}
              <div className="mt-4 pt-4 border-t border-neutral-200 dark:border-neutral-800 space-y-2 text-xs">
                <div className="flex justify-between text-neutral-500">
                  <span>Gross Subtotal:</span>
                  <span className="font-semibold text-neutral-900 dark:text-white">₱{grossSubtotal.toLocaleString()}</span>
                </div>
                {discountAmount > 0 && (
                  <div className="flex justify-between text-emerald-600 dark:text-emerald-400 font-medium">
                    <span>Discount Applied:</span>
                    <span>-₱{discountAmount.toLocaleString()}</span>
                  </div>
                )}
                <div className="flex justify-between items-baseline pt-2 border-t border-dashed border-neutral-200 dark:border-neutral-800">
                  <span className="text-xs font-bold uppercase text-neutral-600 dark:text-neutral-300">Total Payable:</span>
                  <span className="text-2xl font-black text-emerald-600 dark:text-emerald-400">
                    ₱{netPayable.toLocaleString()}
                  </span>
                </div>
              </div>

              {/* Checkout Trigger Button */}
              <button
                type="button"
                id="pos-checkout-btn"
                disabled={cart.length === 0}
                onClick={handleOpenCheckout}
                className="mt-5 w-full py-4 rounded-2xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white font-bold text-sm shadow-md hover:opacity-95 active:scale-95 disabled:opacity-40 disabled:cursor-not-allowed transition-all flex items-center justify-center space-x-2"
              >
                <CreditCard className="w-4 h-4" />
                <span>Pay ₱{netPayable.toLocaleString()} & Print Receipt</span>
              </button>
            </div>

            {/* Quick Shift Recap Card */}
            <div className={`p-5 rounded-3xl border text-xs ${isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-[#80C7F2]/20 shadow-xs'}`}>
              <h3 className="font-bold text-neutral-400 uppercase tracking-wider text-[11px] mb-2.5">
                Today's Register Metrics
              </h3>
              <div className="grid grid-cols-2 gap-3">
                <div className="p-3 rounded-2xl bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800">
                  <p className="text-[11px] text-neutral-500">Today's Revenue</p>
                  <p className="text-base font-black text-emerald-600 dark:text-emerald-400">
                    ₱{todayRevenue.toLocaleString()}
                  </p>
                </div>
                <div className="p-3 rounded-2xl bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800">
                  <p className="text-[11px] text-neutral-500">Units Handed Out</p>
                  <p className="text-base font-black text-neutral-900 dark:text-white">
                    {todayUnits} pcs
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: ZOBAZE POS SYNC & IMPORT/EXPORT HUB */}
      {activeTab === 'zobazeSync' && (
        <div className="space-y-6">
          {/* Connector Banner */}
          <div className="p-6 sm:p-8 rounded-3xl bg-gradient-to-r from-neutral-900 via-neutral-800 to-stone-900 text-white shadow-lg border border-neutral-700">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
              <div className="space-y-2">
                <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-[#F37021]/20 text-[#F37021] text-xs font-bold border border-[#F37021]/30">
                  <Zap className="w-3.5 h-3.5" />
                  <span>ZOBAZE POS DATA BRIDGE ACTIVE</span>
                </div>
                <h2 className="text-2xl font-black tracking-tight">Zobaze POS Integration Hub</h2>
                <p className="text-xs text-neutral-300 max-w-2xl leading-relaxed">
                  Seamlessly connect external Zobaze POS tablet/mobile sales reports to VertexIS. Upload daily Zobaze CSV logs to automatically deplete on-hand branch inventory and sync cloud revenue.
                </p>
              </div>

              <div className="flex flex-wrap items-center gap-3">
                <button
                  type="button"
                  id="export-zobaze-catalog-btn"
                  onClick={exportZobazeCatalog}
                  className="px-4 py-2.5 rounded-2xl bg-white/10 hover:bg-white/20 text-white text-xs font-bold border border-white/20 transition-all flex items-center space-x-2"
                >
                  <Download className="w-4 h-4" />
                  <span>Export Zobaze Catalog</span>
                </button>
                <button
                  type="button"
                  id="export-zobaze-sales-btn"
                  onClick={exportZobazeSales}
                  className="px-4 py-2.5 rounded-2xl bg-[#F37021] hover:bg-[#F37021]/90 text-white text-xs font-bold transition-all flex items-center space-x-2 shadow-md"
                >
                  <FileSpreadsheet className="w-4 h-4" />
                  <span>Export Sales Ledger</span>
                </button>
              </div>
            </div>
          </div>

          {/* Import Panel Grid */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* CSV File Upload / Paste Box */}
            <div className={`p-6 sm:p-8 rounded-3xl border space-y-4 ${isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-[#80C7F2]/20 shadow-xs'}`}>
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2 text-[#F37021]">
                  <Upload className="w-5 h-5" />
                  <h3 className="text-base font-bold text-neutral-900 dark:text-white">Import Zobaze Sales CSV</h3>
                </div>
                <input
                  type="file"
                  ref={fileInputRef}
                  onChange={handleFileUpload}
                  accept=".csv,.txt"
                  className="hidden"
                />
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="text-xs font-bold text-[#80C7F2] hover:underline flex items-center space-x-1"
                >
                  <FileSpreadsheet className="w-3.5 h-3.5" />
                  <span>Browse .CSV File</span>
                </button>
              </div>

              <p className="text-xs text-neutral-500">
                Paste raw sales data or upload an exported CSV from your Zobaze POS register:
              </p>

              <textarea
                value={csvText}
                onChange={(e) => setCsvText(e.target.value)}
                rows={6}
                placeholder={`Flavor, Quantity, Total, Payment Method, Date, Receipt\nUbe Halaya, 4, 380, Cash, 2026-08-20, ZB-1001\nClassic Vanilla, 6, 540, GCash, 2026-08-20, ZB-1002`}
                className="w-full p-3.5 rounded-2xl border border-neutral-200 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-900 text-xs font-mono focus:outline-none focus:ring-2 focus:ring-[#80C7F2]"
              />

              <div className="flex items-center justify-between pt-2">
                <button
                  type="button"
                  onClick={() =>
                    setCsvText(
                      `Flavor, Quantity, Total, Payment Method, Date, Receipt\nUbe Halaya, 5, 475, Cash, ${new Date().toISOString().split('T')[0]}, ZB-TEST-${Math.floor(100 + Math.random() * 900)}\nMatcha Pistachio, 3, 315, GCash, ${new Date().toISOString().split('T')[0]}, ZB-TEST-${Math.floor(100 + Math.random() * 900)}\nLotus Biscoff, 4, 420, Maya, ${new Date().toISOString().split('T')[0]}, ZB-TEST-${Math.floor(100 + Math.random() * 900)}`
                    )
                  }
                  className="text-xs font-semibold text-neutral-500 hover:text-[#F37021]"
                >
                  Load Sample Zobaze Rows
                </button>

                <button
                  type="button"
                  id="process-zobaze-import-btn"
                  disabled={isImporting || !csvText.trim()}
                  onClick={handleImportCsv}
                  className="px-6 py-3 rounded-2xl bg-gradient-to-r from-[#F37021] to-amber-600 hover:opacity-95 text-white text-xs font-bold shadow-md active:scale-95 disabled:opacity-40 transition-all flex items-center space-x-2"
                >
                  {isImporting ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Check className="w-4 h-4" />}
                  <span>Execute Zobaze Inventory Sync</span>
                </button>
              </div>

              {/* Import Results Box */}
              {importResult && (
                <div className="mt-4 p-4 rounded-2xl bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 space-y-2 text-xs">
                  <div className="flex items-center space-x-2 text-emerald-600 dark:text-emerald-400 font-bold">
                    <CheckCircle2 className="w-4 h-4" />
                    <span>Import Complete: {importResult.successCount} sales successfully recorded & inventory depleted!</span>
                  </div>
                  {importResult.errors.length > 0 && (
                    <div className="text-amber-600 dark:text-amber-400 space-y-1">
                      <p className="font-semibold">Notices:</p>
                      {importResult.errors.map((err, idx) => (
                        <p key={idx} className="text-[11px] font-mono">⚠️ {err}</p>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>

            {/* Sync Configuration & Mapping Guide */}
            <div className={`p-6 sm:p-8 rounded-3xl border space-y-4 ${isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-[#80C7F2]/20 shadow-xs'}`}>
              <div className="flex items-center space-x-2 text-[#0c5077] dark:text-[#80C7F2]">
                <Info className="w-5 h-5" />
                <h3 className="text-base font-bold text-neutral-900 dark:text-white">Zobaze Setup & Field Mapping</h3>
              </div>

              <p className="text-xs text-neutral-500 leading-relaxed">
                VertexIS uses intelligent fuzzy matching to align Zobaze POS products with your Marsh Bites recipe catalog.
              </p>

              <div className="space-y-3 text-xs">
                <div className="p-3 rounded-2xl bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 flex items-center justify-between">
                  <div>
                    <p className="font-bold">Branch Device ID</p>
                    <p className="text-[11px] text-neutral-400">Assigned terminal identifier</p>
                  </div>
                  <span className="font-mono text-xs font-bold px-2.5 py-1 rounded-xl bg-[#80C7F2]/15 text-[#0369a1] dark:text-[#80C7F2]">
                    ZB-TERM-{currentBranch.id.toUpperCase()}
                  </span>
                </div>

                <div className="p-3 rounded-2xl bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 flex items-center justify-between">
                  <div>
                    <p className="font-bold">Real-time Stock Depletion</p>
                    <p className="text-[11px] text-neutral-400">Inventory decrements on sync</p>
                  </div>
                  <span className="font-bold text-xs text-emerald-600 dark:text-emerald-400 flex items-center space-x-1">
                    <Check className="w-3.5 h-3.5" />
                    <span>Enabled</span>
                  </span>
                </div>

                <div className="p-3 rounded-2xl bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 flex items-center justify-between">
                  <div>
                    <p className="font-bold">Cloud Firestore Mirroring</p>
                    <p className="text-[11px] text-neutral-400">Central Commissary HQ visibility</p>
                  </div>
                  <span className="font-bold text-xs text-emerald-600 dark:text-emerald-400 flex items-center space-x-1">
                    <Check className="w-3.5 h-3.5" />
                    <span>Active</span>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: SHIFT RECEIPTS & AUDIT LOG */}
      {activeTab === 'receipts' && (
        <div className={`p-6 sm:p-8 rounded-3xl border space-y-4 ${isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-[#80C7F2]/20 shadow-xs'}`}>
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-neutral-200 dark:border-neutral-800">
            <div>
              <h2 className="text-base font-bold text-neutral-900 dark:text-white">Recent Register & Zobaze Transactions</h2>
              <p className="text-xs text-neutral-500">
                Click any receipt to view thermal receipt format or reprint for customer.
              </p>
            </div>
            <div className="text-xs font-bold px-3 py-1 rounded-full bg-emerald-500/15 text-emerald-600 dark:text-emerald-400">
              Total Shift Sales: ₱{todayRevenue.toLocaleString()}
            </div>
          </div>

          <div className="divide-y divide-neutral-200 dark:divide-neutral-800">
            {branchSales.length === 0 ? (
              <div className="py-12 text-center text-neutral-400 text-xs">
                No sales recorded for this branch yet.
              </div>
            ) : (
              branchSales.map((sale) => (
                <div
                  key={sale.id}
                  className="py-3 flex items-center justify-between hover:bg-neutral-50 dark:hover:bg-neutral-900/50 px-2 rounded-2xl transition-colors cursor-pointer"
                  onClick={() =>
                    setActiveReceipt({
                      receiptNumber: sale.receiptPath || sale.id,
                      items: [{ flavor: sale.productName, qty: sale.quantity, unitPrice: sale.total / sale.quantity, total: sale.total }],
                      subtotal: sale.total + (sale.discountAmount || 0),
                      discountAmount: sale.discountAmount || 0,
                      discountType: sale.discountType || 'None',
                      totalAmount: sale.total,
                      paymentMethod: sale.paymentMethod || 'Cash',
                      amountTendered: sale.amountTendered || sale.total,
                      change: sale.change || 0,
                      date: new Date(sale.date).toLocaleString('en-US', { dateStyle: 'medium', timeStyle: 'short' }),
                      cashierName: sale.cashierName || 'Cashier',
                      customerName: sale.customerName,
                    })
                  }
                >
                  <div className="flex items-center space-x-3 min-w-0">
                    <div className="w-10 h-10 rounded-2xl bg-neutral-100 dark:bg-neutral-800 flex items-center justify-center text-neutral-500 flex-shrink-0">
                      <Receipt className="w-4 h-4" />
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center space-x-2">
                        <p className="text-xs font-mono font-bold text-neutral-900 dark:text-white truncate">
                          {sale.receiptPath || sale.id}
                        </p>
                        <span className="text-[10px] px-2 py-0.5 rounded-full bg-neutral-100 dark:bg-neutral-800 text-neutral-500 font-semibold">
                          {sale.paymentMethod || 'Cash'}
                        </span>
                        {sale.source === 'Zobaze POS Sync' && (
                          <span className="text-[10px] px-2 py-0.5 rounded-full bg-[#F37021]/15 text-[#F37021] font-bold">
                            ZOBAZE
                          </span>
                        )}
                      </div>
                      <p className="text-[11px] text-neutral-400 mt-0.5 truncate">
                        {sale.productName} • Qty: {sale.quantity} • {new Date(sale.date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </p>
                    </div>
                  </div>

                  <div className="text-right flex items-center space-x-3 flex-shrink-0">
                    <div>
                      <p className="font-black text-sm text-emerald-600 dark:text-emerald-400">
                        ₱{sale.total.toLocaleString()}
                      </p>
                      <p className="text-[10px] text-neutral-400">
                        {sale.customerName ? `For ${sale.customerName}` : 'Walk-in'}
                      </p>
                    </div>
                    <ChevronRight className="w-4 h-4 text-neutral-400" />
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}

      {/* CHECKOUT PAYMENT MODAL */}
      {isCheckoutOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className={`w-full max-w-md p-6 sm:p-8 rounded-3xl border shadow-2xl space-y-5 ${isDark ? 'bg-[#161616] border-neutral-700 text-white' : 'bg-white border-neutral-200 text-neutral-900'}`}>
            <div className="flex items-center justify-between pb-3 border-b border-neutral-200 dark:border-neutral-800">
              <div className="flex items-center space-x-2">
                <Banknote className="w-5 h-5 text-emerald-600" />
                <h3 className="text-lg font-black tracking-tight">Payment & Tender</h3>
              </div>
              <button
                type="button"
                onClick={() => setIsCheckoutOpen(false)}
                className="text-neutral-400 hover:text-neutral-600 p-1"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Payment Method Selector */}
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-neutral-400 mb-2">
                Payment Channel:
              </label>
              <div className="grid grid-cols-3 gap-2">
                {[
                  { id: 'Cash', label: 'Cash', icon: Banknote },
                  { id: 'GCash', label: 'GCash', icon: Smartphone },
                  { id: 'Maya', label: 'Maya', icon: Smartphone },
                  { id: 'Card', label: 'Card', icon: CreditCard },
                  { id: 'Zobaze POS', label: 'Zobaze POS', icon: RefreshCw },
                ].map((pm) => {
                  const Icon = pm.icon;
                  const isSelected = paymentMethod === pm.id;
                  return (
                    <button
                      key={pm.id}
                      type="button"
                      onClick={() => {
                        setPaymentMethod(pm.id as any);
                        if (pm.id !== 'Cash') {
                          setAmountTendered(netPayable.toString());
                        }
                      }}
                      className={`p-3 rounded-2xl border text-xs font-bold flex flex-col items-center justify-center gap-1.5 transition-all ${
                        isSelected
                          ? 'border-emerald-600 bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 font-extrabold shadow-xs'
                          : 'border-neutral-200 dark:border-neutral-800 text-neutral-500 hover:border-neutral-400'
                      }`}
                    >
                      <Icon className="w-4 h-4" />
                      <span>{pm.label}</span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Amount Payable Card */}
            <div className="p-4 rounded-2xl bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 flex items-center justify-between">
              <div>
                <p className="text-[11px] font-bold text-neutral-400 uppercase">Amount Due:</p>
                <p className="text-2xl font-black text-emerald-600 dark:text-emerald-400">₱{netPayable.toLocaleString()}</p>
              </div>
              <div className="text-right text-xs text-neutral-500">
                <p>{totalCartUnits} Gourmet Units</p>
                {discountAmount > 0 && <p className="text-emerald-500 font-semibold">-₱{discountAmount} Discount</p>}
              </div>
            </div>

            {/* Cash Tender & Quick Buttons */}
            {paymentMethod === 'Cash' && (
              <div className="space-y-3">
                <label className="block text-xs font-bold uppercase tracking-wider text-neutral-400">
                  Cash Tendered:
                </label>
                <input
                  type="number"
                  id="cash-tendered-input"
                  value={amountTendered}
                  onChange={(e) => setAmountTendered(e.target.value)}
                  placeholder="Enter cash received..."
                  className="w-full px-4 py-3 rounded-2xl border border-neutral-200 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-900 text-lg font-black focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />

                {/* Quick Bills */}
                <div className="flex flex-wrap gap-2 pt-1">
                  {[netPayable, 100, 200, 500, 1000].map((val) => (
                    <button
                      key={val}
                      type="button"
                      onClick={() => setAmountTendered(val.toString())}
                      className="px-3 py-1.5 rounded-xl border border-neutral-200 dark:border-neutral-700 text-xs font-bold hover:bg-neutral-100 dark:hover:bg-neutral-800"
                    >
                      {val === netPayable ? 'Exact (₱' + val + ')' : '₱' + val}
                    </button>
                  ))}
                </div>

                {/* Change Computation */}
                <div className="p-3.5 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-between">
                  <span className="text-xs font-bold text-neutral-600 dark:text-neutral-300">Change Due to Customer:</span>
                  <span className="text-xl font-black text-emerald-600 dark:text-emerald-400">
                    ₱{changeDue.toLocaleString()}
                  </span>
                </div>
              </div>
            )}

            {/* Digital Wallet Reference */}
            {(paymentMethod === 'GCash' || paymentMethod === 'Maya' || paymentMethod === 'Card') && (
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-neutral-400 mb-1">
                  {paymentMethod} Ref / Auth Number:
                </label>
                <input
                  type="text"
                  value={referenceNumber}
                  onChange={(e) => setReferenceNumber(e.target.value)}
                  placeholder="e.g. 9823-1029-4819"
                  className="w-full px-4 py-2.5 rounded-2xl border border-neutral-200 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-900 text-xs focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
              </div>
            )}

            {/* Complete Transaction Action */}
            <button
              type="button"
              id="confirm-checkout-btn"
              onClick={handleFinalizeTransaction}
              className="w-full py-4 rounded-2xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:opacity-95 text-white font-bold text-sm shadow-lg active:scale-95 transition-all flex items-center justify-center space-x-2"
            >
              <Check className="w-5 h-5" />
              <span>Confirm & Print Receipt</span>
            </button>
          </div>
        </div>
      )}

      {/* THERMAL PRINT RECEIPT MODAL */}
      {activeReceipt && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className={`w-full max-w-sm p-6 rounded-3xl border shadow-2xl space-y-4 max-h-[90vh] overflow-y-auto ${isDark ? 'bg-[#181818] border-neutral-700 text-white' : 'bg-white border-neutral-300 text-neutral-900'}`}>
            <div className="flex items-center justify-between pb-2 border-b border-neutral-200 dark:border-neutral-800">
              <span className="text-xs font-bold text-[#F37021] uppercase tracking-wider">Official Thermal Receipt</span>
              <button
                type="button"
                onClick={() => setActiveReceipt(null)}
                className="text-neutral-400 hover:text-neutral-600 p-1"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Printable Thermal Receipt Card */}
            <div className="p-5 rounded-2xl bg-neutral-50 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 text-neutral-800 dark:text-neutral-200 font-mono text-xs space-y-3 print:border-none">
              {/* Header */}
              <div className="text-center space-y-1 pb-2 border-b border-dashed border-neutral-300 dark:border-neutral-700">
                <p className="font-black text-base tracking-tight">MARSH BITES</p>
                <p className="text-[10px] text-neutral-500">Handmade Gourmet Marshmallows • Bicol Commissary</p>
                <p className="text-[11px] font-bold mt-1">{currentBranch.name}</p>
                <p className="text-[10px] text-neutral-400">{currentBranch.location}</p>
              </div>

              {/* Meta */}
              <div className="text-[11px] space-y-0.5 text-neutral-600 dark:text-neutral-400 pb-2 border-b border-dashed border-neutral-300 dark:border-neutral-700">
                <div className="flex justify-between">
                  <span>Receipt #:</span>
                  <span className="font-bold text-neutral-900 dark:text-white">{activeReceipt.receiptNumber}</span>
                </div>
                <div className="flex justify-between">
                  <span>Date/Time:</span>
                  <span>{activeReceipt.date}</span>
                </div>
                <div className="flex justify-between">
                  <span>Cashier:</span>
                  <span>{activeReceipt.cashierName}</span>
                </div>
                {activeReceipt.customerName && (
                  <div className="flex justify-between">
                    <span>Customer:</span>
                    <span>{activeReceipt.customerName}</span>
                  </div>
                )}
              </div>

              {/* Items Table */}
              <div className="space-y-1.5 pb-2 border-b border-dashed border-neutral-300 dark:border-neutral-700">
                {activeReceipt.items.map((it, idx) => (
                  <div key={idx} className="flex justify-between text-[11px]">
                    <span className="truncate pr-2">{it.flavor} x{it.qty}</span>
                    <span className="font-bold">₱{it.total}</span>
                  </div>
                ))}
              </div>

              {/* Totals */}
              <div className="space-y-1 text-[11px] pb-2 border-b border-dashed border-neutral-300 dark:border-neutral-700">
                <div className="flex justify-between text-neutral-500">
                  <span>Subtotal:</span>
                  <span>₱{activeReceipt.subtotal}</span>
                </div>
                {activeReceipt.discountAmount > 0 && (
                  <div className="flex justify-between text-emerald-600">
                    <span>Discount ({activeReceipt.discountType}):</span>
                    <span>-₱{activeReceipt.discountAmount}</span>
                  </div>
                )}
                <div className="flex justify-between text-sm font-black pt-1">
                  <span>TOTAL:</span>
                  <span className="text-emerald-600 dark:text-emerald-400">₱{activeReceipt.totalAmount}</span>
                </div>
              </div>

              {/* Payment Details */}
              <div className="space-y-0.5 text-[10px] text-neutral-500 pb-2 border-b border-dashed border-neutral-300 dark:border-neutral-700">
                <div className="flex justify-between">
                  <span>Payment:</span>
                  <span className="font-bold">{activeReceipt.paymentMethod}</span>
                </div>
                {activeReceipt.amountTendered !== undefined && (
                  <div className="flex justify-between">
                    <span>Tendered:</span>
                    <span>₱{activeReceipt.amountTendered}</span>
                  </div>
                )}
                {activeReceipt.change !== undefined && (
                  <div className="flex justify-between">
                    <span>Change:</span>
                    <span>₱{activeReceipt.change}</span>
                  </div>
                )}
              </div>

              {/* Barcode & Footer */}
              <div className="text-center pt-1 space-y-1">
                <p className="font-mono text-xs tracking-widest text-neutral-400 select-none">
                  ||| | ||||| || |||| ||| ||
                </p>
                <p className="text-[10px] text-neutral-500 font-sans">Thank you for craving Marsh Bites!</p>
              </div>
            </div>

            {/* Actions */}
            <div className="flex items-center space-x-2 pt-2">
              <button
                type="button"
                onClick={() => window.print()}
                className="flex-1 py-3 rounded-2xl bg-neutral-900 dark:bg-white text-white dark:text-neutral-900 text-xs font-bold hover:opacity-90 transition-all flex items-center justify-center space-x-2"
              >
                <Printer className="w-4 h-4" />
                <span>Print Thermal Receipt</span>
              </button>
              <button
                type="button"
                onClick={() => setActiveReceipt(null)}
                className="px-4 py-3 rounded-2xl border border-neutral-300 dark:border-neutral-700 text-xs font-bold hover:bg-neutral-100 dark:hover:bg-neutral-800"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
