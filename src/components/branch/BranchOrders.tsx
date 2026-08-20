import React, { useState } from 'react';
import { useData } from '../../context/DataContext';
import { Order, OrderItem, ProductionStage } from '../../types';
import {
  ShoppingBag,
  Plus,
  Minus,
  CheckCircle2,
  Clock,
  XCircle,
  Upload,
  Image as ImageIcon,
  AlertCircle,
  ExternalLink,
  Sparkles,
  Store,
  Flame,
  Snowflake,
  Box,
  Truck,
  ChefHat,
} from 'lucide-react';

const STAGE_CONFIG: Record<ProductionStage, { label: string; icon: React.FC<{ className?: string }>; color: string; bg: string }> = {
  queued: {
    label: 'Queued for Kitchen Batching',
    icon: Clock,
    color: 'text-amber-600 dark:text-amber-400',
    bg: 'bg-amber-500/10 border-amber-500/30',
  },
  in_kettle: {
    label: 'In Kettle (Syrup & Fluff Whipping)',
    icon: Flame,
    color: 'text-orange-600 dark:text-orange-400',
    bg: 'bg-orange-500/10 border-orange-500/30',
  },
  curing: {
    label: 'Curing & Cooling Slabs',
    icon: Snowflake,
    color: 'text-sky-600 dark:text-sky-400',
    bg: 'bg-sky-500/10 border-sky-500/30',
  },
  packaged: {
    label: 'QC Inspected & Heat Sealed',
    icon: Box,
    color: 'text-purple-600 dark:text-purple-400',
    bg: 'bg-purple-500/10 border-purple-500/30',
  },
  ready_for_dispatch: {
    label: 'Ready for Courier Dispatch',
    icon: Truck,
    color: 'text-emerald-600 dark:text-emerald-400',
    bg: 'bg-emerald-500/10 border-emerald-500/30',
  },
};

const SAMPLE_PAYMENT_PROOFS = [
  { label: 'BDO Online Transfer Receipt', url: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=600&auto=format&fit=crop&q=80' },
  { label: 'GCash Payment Confirmation', url: 'https://images.unsplash.com/photo-1554224154-26032ffc0d07?w=600&auto=format&fit=crop&q=80' },
  { label: 'Bank Deposit Slip', url: 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=600&auto=format&fit=crop&q=80' },
];

export const BranchOrders: React.FC = () => {
  const {
    products,
    currentBranch,
    createOrder,
    uploadPaymentProof,
    getOrdersForBranch,
    getInventoryForBranch,
    themeMode,
  } = useData();

  const [quantities, setQuantities] = useState<Record<string, number>>({});
  const [selectedOrderForProof, setSelectedOrderForProof] = useState<Order | null>(null);
  const [proofUrl, setProofUrl] = useState('');
  const [orderSuccessMsg, setOrderSuccessMsg] = useState<string | null>(null);

  if (!currentBranch) return null;

  const branchId = currentBranch.id;
  const branchOrders = getOrdersForBranch(branchId);
  const branchInventory = getInventoryForBranch(branchId);
  const isDark = themeMode === 'dark';

  const handleQtyChange = (productId: string, delta: number) => {
    setQuantities((prev) => {
      const current = prev[productId] || 0;
      const next = Math.max(0, current + delta);
      return { ...prev, [productId]: next };
    });
  };

  const selectedItems = products
    .filter((p) => (quantities[p.id] || 0) > 0)
    .map((p) => ({
      productId: p.id,
      productName: `${p.flavor} (${p.name})`,
      quantity: quantities[p.id],
      unitPrice: p.price,
    }));

  const cartTotal = selectedItems.reduce((sum, i) => sum + i.quantity * i.unitPrice, 0);
  const totalCartUnits = selectedItems.reduce((sum, i) => sum + i.quantity, 0);

  const handlePlaceOrder = () => {
    if (selectedItems.length === 0) return;
    const newOrd = createOrder(selectedItems);
    if (newOrd) {
      setQuantities({});
      setOrderSuccessMsg(`Order #${newOrd.id} created successfully! Please attach proof of payment below.`);
      setSelectedOrderForProof(newOrd);
      setProofUrl(SAMPLE_PAYMENT_PROOFS[0].url);
      setTimeout(() => setOrderSuccessMsg(null), 6000);
    }
  };

  const handleUploadProofSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedOrderForProof || !proofUrl.trim()) return;
    uploadPaymentProof(selectedOrderForProof.id, proofUrl.trim());
    setSelectedOrderForProof(null);
    setProofUrl('');
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black tracking-tight">Commissary Stock Requisition</h1>
          <p className="text-xs text-neutral-500 font-medium">
            Order fresh gourmet marshmallow batches handmade at Central Bicol Commissary.
          </p>
        </div>
      </div>

      {orderSuccessMsg && (
        <div className="p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-600 dark:text-emerald-400 text-xs font-bold flex items-center space-x-2">
          <CheckCircle2 className="w-4 h-4 flex-shrink-0" />
          <span>{orderSuccessMsg}</span>
        </div>
      )}

      {/* Flavor Ordering Catalog */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {products.map((prod) => {
          const invItem = branchInventory.find((i) => i.productId === prod.id);
          const currentStock = invItem ? invItem.stock : 0;
          const currentQty = quantities[prod.id] || 0;

          return (
            <div
              key={prod.id}
              className={`p-5 rounded-3xl border transition-all flex flex-col justify-between ${
                isDark
                  ? 'bg-[#161616] border-neutral-800'
                  : 'bg-white border-[#80C7F2]/20 shadow-xs'
              }`}
            >
              <div>
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#80C7F2]/15 text-[#1a7bb5] dark:text-[#80C7F2]">
                    Gourmet Recipe
                  </span>
                  <span className="text-xs font-black text-emerald-600 dark:text-emerald-400">
                    ₱{prod.price} / unit
                  </span>
                </div>

                <h3 className="text-base font-black mt-2 leading-snug">
                  {prod.flavor}
                </h3>
                <p className="text-xs text-neutral-500 mt-1">
                  Branch On-Hand: <strong className={currentStock <= 5 ? 'text-red-500 font-black' : 'text-neutral-700 dark:text-neutral-300'}>{currentStock} units</strong>
                </p>
              </div>

              {/* Quantity Stepper */}
              <div className="mt-4 pt-3 border-t border-neutral-100 dark:border-neutral-800 flex items-center justify-between">
                <span className="text-xs font-bold text-neutral-400">Order Quantity</span>
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => handleQtyChange(prod.id, -5)}
                    className="w-8 h-8 rounded-xl border border-neutral-300 dark:border-neutral-700 flex items-center justify-center font-bold hover:bg-neutral-100 dark:hover:bg-neutral-800"
                  >
                    -5
                  </button>
                  <button
                    onClick={() => handleQtyChange(prod.id, -1)}
                    className="w-8 h-8 rounded-xl border border-neutral-300 dark:border-neutral-700 flex items-center justify-center font-bold hover:bg-neutral-100 dark:hover:bg-neutral-800"
                  >
                    -1
                  </button>
                  <span className="w-10 text-center font-black text-sm">{currentQty}</span>
                  <button
                    onClick={() => handleQtyChange(prod.id, 1)}
                    className="w-8 h-8 rounded-xl border border-neutral-300 dark:border-neutral-700 flex items-center justify-center font-bold hover:bg-neutral-100 dark:hover:bg-neutral-800"
                  >
                    +1
                  </button>
                  <button
                    onClick={() => handleQtyChange(prod.id, 5)}
                    className="w-8 h-8 rounded-xl border border-neutral-300 dark:border-neutral-700 flex items-center justify-center font-bold hover:bg-neutral-100 dark:hover:bg-neutral-800"
                  >
                    +5
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Cart Summary & Order Submit */}
      {selectedItems.length > 0 && (
        <div className={`p-6 rounded-3xl border ${
          isDark
            ? 'bg-neutral-900 border-[#80C7F2]/40 text-white'
            : 'bg-gradient-to-r from-sky-50 via-white to-orange-50 border-[#80C7F2]/40 text-neutral-900'
        }`}>
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h2 className="text-base font-bold">Stock Requisition Cart</h2>
              <p className="text-xs text-neutral-500">
                {totalCartUnits} total units selected across {selectedItems.length} flavor lines
              </p>
            </div>

            <div className="flex items-center space-x-4">
              <div className="text-right">
                <span className="text-xs text-neutral-400">Total Payable:</span>
                <p className="text-xl font-black text-emerald-600 dark:text-emerald-400">
                  ₱{cartTotal.toLocaleString()}
                </p>
              </div>

              <button
                onClick={handlePlaceOrder}
                className="px-5 py-3 rounded-2xl bg-gradient-to-r from-[#F37021] to-amber-500 text-white font-bold text-sm shadow-md hover:opacity-95 active:scale-95 transition-all flex items-center space-x-2"
              >
                <ShoppingBag className="w-4 h-4" />
                <span>Submit Stock Order</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Order Status History Table */}
      <div className="space-y-3 pt-4">
        <h2 className="text-base font-bold">Branch Requisition History</h2>

        {branchOrders.length === 0 ? (
          <div className={`p-12 text-center rounded-3xl border ${
            isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-neutral-200'
          }`}>
            <ShoppingBag className="w-12 h-12 text-neutral-400 mx-auto mb-3 opacity-60" />
            <p className="text-sm font-bold">No orders placed yet</p>
          </div>
        ) : (
          branchOrders.map((ord) => {
            const stage = ord.productionStage || 'queued';
            const stageInfo = STAGE_CONFIG[stage] || STAGE_CONFIG.queued;
            const StageIcon = stageInfo.icon;

            return (
              <div
                key={ord.id}
                className={`p-5 rounded-3xl border transition-all space-y-3.5 ${
                  isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-neutral-200 shadow-xs'
                }`}
              >
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div className="space-y-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-mono text-xs text-neutral-400">#{ord.id}</span>
                      {ord.batchCode && (
                        <span className="px-2.5 py-0.5 rounded-full text-[10px] font-mono font-bold bg-[#80C7F2]/15 text-[#1a7bb5] dark:text-[#80C7F2] border border-[#80C7F2]/30">
                          Batch: {ord.batchCode}
                        </span>
                      )}
                      <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                        ord.status === 'approved'
                          ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400'
                          : ord.status === 'waitingApproval'
                          ? 'bg-amber-500/15 text-amber-600 dark:text-amber-400'
                          : ord.status === 'rejected'
                          ? 'bg-red-500/15 text-red-600 dark:text-red-400'
                          : 'bg-sky-500/15 text-sky-600 dark:text-sky-400'
                      }`}>
                        {ord.status === 'waitingApproval' ? 'Under HQ Review' : ord.status}
                      </span>
                      <span className="text-xs text-neutral-400">
                        {new Date(ord.createdAt).toLocaleString()}
                      </span>
                    </div>

                    <div className="text-xs text-neutral-600 dark:text-neutral-300">
                      {ord.items.map((i) => `${i.quantity}x ${i.productName}`).join(' • ')}
                    </div>
                  </div>

                  <div className="flex items-center justify-between sm:justify-end space-x-4">
                    <div className="text-left sm:text-right">
                      <p className="text-xs text-neutral-400">Total Value</p>
                      <p className="text-base font-black text-emerald-600 dark:text-emerald-400">
                        ₱{ord.totalAmount.toLocaleString()}
                      </p>
                    </div>

                    {ord.status === 'pending' && (
                      <button
                        onClick={() => {
                          setSelectedOrderForProof(ord);
                          setProofUrl(SAMPLE_PAYMENT_PROOFS[0].url);
                        }}
                        className="px-3.5 py-2 rounded-xl bg-[#80C7F2] text-neutral-900 text-xs font-bold hover:bg-[#6ab9e8] transition-all flex items-center space-x-1.5"
                      >
                        <Upload className="w-3.5 h-3.5" />
                        <span>Upload Proof</span>
                      </button>
                    )}

                    {ord.proofImagePath && (
                      <a
                        href={ord.proofImagePath}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="p-2 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-neutral-500 hover:text-[#80C7F2]"
                        title="View uploaded proof"
                      >
                        <ImageIcon className="w-4 h-4" />
                      </a>
                    )}
                  </div>
                </div>

                {/* Made-to-Order Confectionery Lifecycle Bar */}
                <div className="pt-3 border-t border-neutral-100 dark:border-neutral-800 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div className="flex items-center space-x-2">
                    <span className="text-[11px] font-bold text-neutral-400 uppercase tracking-wider">MTO Kitchen Status:</span>
                    <span className={`px-2.5 py-1 rounded-xl text-xs font-bold border flex items-center space-x-1.5 ${stageInfo.bg} ${stageInfo.color}`}>
                      <StageIcon className="w-3.5 h-3.5" />
                      <span>{stageInfo.label}</span>
                    </span>
                  </div>

                  {ord.estimatedReadyDate && (
                    <span className="text-[11px] text-neutral-500 font-medium">
                      Estimated Dispatch: <strong className="text-neutral-700 dark:text-neutral-300">{ord.estimatedReadyDate}</strong>
                    </span>
                  )}
                </div>

                {ord.rejectionReason && (
                  <p className="text-xs text-red-500 font-semibold pt-1">
                    Rejection Reason: {ord.rejectionReason}
                  </p>
                )}
              </div>
            );
          })
        )}
      </div>

      {/* Proof of Payment Upload Modal */}
      {selectedOrderForProof && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4">
          <div className={`w-full max-w-md rounded-3xl p-6 shadow-2xl border ${
            isDark ? 'bg-[#1c1c1c] border-neutral-700 text-white' : 'bg-white border-neutral-200 text-neutral-900'
          }`}>
            <div className="flex items-center space-x-2 text-[#80C7F2] mb-2">
              <Upload className="w-5 h-5" />
              <h3 className="text-base font-bold">Attach Proof of Payment</h3>
            </div>
            <p className="text-xs text-neutral-500">
              Submit payment confirmation receipt for Order #{selectedOrderForProof.id} (₱{selectedOrderForProof.totalAmount.toLocaleString()}).
            </p>

            {/* Commissary Payment Account Details */}
            <div className="my-3 p-3 rounded-2xl bg-[#80C7F2]/10 border border-[#80C7F2]/30 text-xs space-y-1">
              <p className="font-bold text-[#1a7bb5] dark:text-[#80C7F2]">HQ Payment Account:</p>
              <p className="text-neutral-600 dark:text-neutral-300">Bank: BDO Unibank • Acct: 0048-2918-4491</p>
              <p className="text-neutral-600 dark:text-neutral-300">GCash / Maya: 0917-884-2104 (Marsh Bites PH)</p>
            </div>

            {/* Demo Presets */}
            <div className="mb-3">
              <p className="text-[11px] font-bold uppercase text-neutral-400 mb-1.5">
                Select Demo Receipt Preset:
              </p>
              <div className="space-y-1.5">
                {SAMPLE_PAYMENT_PROOFS.map((preset, i) => (
                  <button
                    key={i}
                    type="button"
                    onClick={() => setProofUrl(preset.url)}
                    className={`w-full text-left p-2 rounded-xl border text-xs transition-all ${
                      proofUrl === preset.url
                        ? 'border-[#80C7F2] bg-[#80C7F2]/10 font-bold text-[#1a7bb5] dark:text-[#80C7F2]'
                        : 'border-neutral-200 dark:border-neutral-800 hover:bg-neutral-100 dark:hover:bg-neutral-800'
                    }`}
                  >
                    ✓ {preset.label}
                  </button>
                ))}
              </div>
            </div>

            <form onSubmit={handleUploadProofSubmit} className="space-y-3 text-xs">
              <div>
                <label className="block font-bold uppercase tracking-wider text-neutral-400 mb-1">
                  Or Paste Receipt Image URL
                </label>
                <input
                  type="url"
                  required
                  value={proofUrl}
                  onChange={(e) => setProofUrl(e.target.value)}
                  placeholder="https://..."
                  className={`w-full p-2.5 rounded-xl border ${
                    isDark ? 'bg-neutral-900 border-neutral-700 text-white' : 'bg-neutral-50 border-neutral-200'
                  }`}
                />
              </div>

              <div className="flex items-center justify-end space-x-2 pt-2">
                <button
                  type="button"
                  onClick={() => setSelectedOrderForProof(null)}
                  className="px-3.5 py-2 font-medium rounded-xl border border-neutral-300 dark:border-neutral-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 font-bold rounded-xl bg-[#F37021] text-white hover:bg-[#d85e15]"
                >
                  Upload & Submit to HQ
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
