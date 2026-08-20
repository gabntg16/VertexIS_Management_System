import React, { useState } from 'react';
import { useData } from '../../context/DataContext';
import { Order, OrderStatus, ProductionStage } from '../../types';
import {
  ShoppingBag,
  CheckCircle2,
  XCircle,
  Clock,
  Search,
  Filter,
  Image as ImageIcon,
  Truck,
  ExternalLink,
  ChevronRight,
  AlertCircle,
  FileText,
  Flame,
  ChefHat,
  Box,
} from 'lucide-react';

export const AdminOrders: React.FC = () => {
  const {
    orders,
    approveOrder,
    rejectOrder,
    deleteOrder,
    createDelivery,
    deliveries,
    produceForOrder,
    updateOrderProductionStage,
    themeMode,
  } = useData();

  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');
  const [showDeliveryModal, setShowDeliveryModal] = useState(false);
  const [courierName, setCourierName] = useState('LBC Express');
  const [trackingNumber, setTrackingNumber] = useState('');
  const [deliveryAddress, setDeliveryAddress] = useState('');
  const [deliveryNotes, setDeliveryNotes] = useState('');

  const isDark = themeMode === 'dark';

  const filteredOrders = orders.filter((o) => {
    const matchesStatus =
      statusFilter === 'all' ? true : o.status === statusFilter;
    const matchesSearch =
      o.branchName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      o.id.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesStatus && matchesSearch;
  });

  const handleApprove = (orderId: string) => {
    approveOrder(orderId);
    if (selectedOrder && selectedOrder.id === orderId) {
      setSelectedOrder({ ...selectedOrder, status: 'approved' });
    }
  };

  const handleRejectSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedOrder || !rejectionReason.trim()) return;
    rejectOrder(selectedOrder.id, rejectionReason.trim());
    setSelectedOrder({
      ...selectedOrder,
      status: 'rejected',
      rejectionReason: rejectionReason.trim(),
    });
    setShowRejectModal(false);
    setRejectionReason('');
  };

  const handleCreateDeliverySubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedOrder) return;
    createDelivery(
      selectedOrder.id,
      deliveryAddress || `${selectedOrder.branchName} Main Branch`,
      courierName,
      trackingNumber,
      new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(),
      deliveryNotes
    );
    setShowDeliveryModal(false);
    setCourierName('LBC Express');
    setTrackingNumber('');
    setDeliveryAddress('');
    setDeliveryNotes('');
  };

  return (
    <div className="space-y-6">
      {/* Header Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black tracking-tight">Branch Stock Orders</h1>
          <p className="text-xs text-neutral-500 font-medium">
            Review stock requisitions, verify proof of payment, and dispatch deliveries.
          </p>
        </div>

        {/* Filter Badges */}
        <div className="flex items-center space-x-1.5 overflow-x-auto pb-1">
          {[
            { id: 'all', label: 'All Orders' },
            { id: 'waitingApproval', label: 'Payment Uploaded' },
            { id: 'pending', label: 'Pending' },
            { id: 'approved', label: 'Approved' },
            { id: 'rejected', label: 'Rejected' },
          ].map((f) => (
            <button
              key={f.id}
              onClick={() => setStatusFilter(f.id)}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                statusFilter === f.id
                  ? 'bg-[#F37021] text-white shadow-xs'
                  : isDark
                  ? 'bg-neutral-800 text-neutral-400 hover:bg-neutral-700'
                  : 'bg-neutral-100 text-neutral-600 hover:bg-neutral-200'
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>
      </div>

      {/* Search Input */}
      <div className="relative">
        <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-neutral-400">
          <Search className="w-4 h-4" />
        </div>
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search by branch name or order ID..."
          className={`w-full pl-10 pr-4 py-2.5 rounded-xl text-sm border focus:outline-none focus:ring-2 focus:ring-[#80C7F2] ${
            isDark
              ? 'bg-[#161616] border-neutral-800 text-white placeholder-neutral-500'
              : 'bg-white border-neutral-200 text-neutral-900 placeholder-neutral-400'
          }`}
        />
      </div>

      {/* Orders List */}
      <div className="space-y-3">
        {filteredOrders.length === 0 ? (
          <div className={`p-12 text-center rounded-3xl border ${
            isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-neutral-200'
          }`}>
            <ShoppingBag className="w-12 h-12 text-neutral-400 mx-auto mb-3 opacity-60" />
            <p className="text-sm font-bold">No orders found</p>
            <p className="text-xs text-neutral-500 mt-1">Try selecting a different filter or search keyword.</p>
          </div>
        ) : (
          filteredOrders.map((ord) => {
            const hasDelivery = deliveries.some((d) => d.orderId === ord.id);
            return (
              <div
                key={ord.id}
                className={`p-4 sm:p-5 rounded-2xl border transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4 ${
                  isDark ? 'bg-[#161616] border-neutral-800 hover:border-neutral-700' : 'bg-white border-neutral-200 hover:border-[#80C7F2]/40 shadow-xs'
                }`}
              >
                <div className="space-y-1.5">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="font-extrabold text-sm sm:text-base">{ord.branchName}</span>
                    <span className="text-xs font-mono text-neutral-400">#{ord.id}</span>
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
                      {ord.status === 'waitingApproval' ? 'Payment Uploaded' : ord.status}
                    </span>
                    {ord.productionStage && (
                      <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-orange-500/10 text-orange-600 dark:text-orange-400 border border-orange-500/20 flex items-center space-x-1">
                        <Flame className="w-3 h-3" />
                        <span>MTO: {ord.productionStage.replace('_', ' ')}</span>
                      </span>
                    )}
                  </div>

                  <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-neutral-500">
                    <span>
                      {ord.items.reduce((sum, i) => sum + i.quantity, 0)} units ({ord.items.length} flavor types)
                    </span>
                    <span>•</span>
                    <span>{new Date(ord.createdAt).toLocaleString()}</span>
                    {ord.proofImagePath && (
                      <span className="inline-flex items-center space-x-1 text-[#80C7F2] font-semibold">
                        <ImageIcon className="w-3.5 h-3.5" />
                        <span>Proof Attached</span>
                      </span>
                    )}
                    {hasDelivery && (
                      <span className="inline-flex items-center space-x-1 text-emerald-600 dark:text-emerald-400 font-semibold">
                        <Truck className="w-3.5 h-3.5" />
                        <span>Dispatched</span>
                      </span>
                    )}
                  </div>
                </div>

                <div className="flex items-center justify-between sm:justify-end space-x-3 pt-2 sm:pt-0 border-t sm:border-t-0 border-neutral-100 dark:border-neutral-800">
                  <div className="text-left sm:text-right">
                    <p className="text-xs text-neutral-400">Total Amount</p>
                    <p className="text-base font-black text-emerald-600 dark:text-emerald-400">
                      ₱{ord.totalAmount.toLocaleString()}
                    </p>
                  </div>

                  <button
                    onClick={() => setSelectedOrder(ord)}
                    className="px-3.5 py-2 rounded-xl bg-neutral-100 dark:bg-neutral-800 hover:bg-[#80C7F2]/20 hover:text-[#1a7bb5] dark:hover:text-[#80C7F2] text-xs font-bold transition-colors flex items-center space-x-1"
                  >
                    <span>Inspect</span>
                    <ChevronRight className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Order Details Modal */}
      {selectedOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 overflow-y-auto">
          <div className={`w-full max-w-2xl rounded-3xl p-6 shadow-2xl border my-8 ${
            isDark ? 'bg-[#1c1c1c] border-neutral-700 text-white' : 'bg-white border-neutral-200 text-neutral-900'
          }`}>
            <div className="flex items-center justify-between border-b border-neutral-200 dark:border-neutral-800 pb-4">
              <div>
                <span className="text-xs font-mono text-neutral-400">ORDER #{selectedOrder.id}</span>
                <h2 className="text-xl font-bold">{selectedOrder.branchName}</h2>
                <p className="text-xs text-neutral-500">
                  Submitted {new Date(selectedOrder.createdAt).toLocaleString()}
                </p>
              </div>
              <button
                onClick={() => setSelectedOrder(null)}
                className="p-2 rounded-xl hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-400"
              >
                ✕
              </button>
            </div>

            {/* Items Table */}
            <div className="mt-4">
              <h3 className="text-xs font-bold uppercase tracking-wider text-neutral-400 mb-2">
                Order Items & Flavor Breakdown
              </h3>
              <div className="space-y-2 max-h-48 overflow-y-auto pr-1">
                {selectedOrder.items.map((item, idx) => (
                  <div
                    key={idx}
                    className="flex items-center justify-between p-3 rounded-xl bg-neutral-50 dark:bg-neutral-900/80 border border-neutral-200 dark:border-neutral-800 text-xs"
                  >
                    <div>
                      <p className="font-bold">{item.productName}</p>
                      <p className="text-neutral-500">₱{item.unitPrice} each</p>
                    </div>
                    <div className="text-right">
                      <p className="font-bold">x {item.quantity} units</p>
                      <p className="font-semibold text-emerald-600 dark:text-emerald-400">
                        ₱{(item.quantity * item.unitPrice).toLocaleString()}
                      </p>
                    </div>
                  </div>
                ))}
              </div>

              <div className="mt-3 p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-between text-sm font-bold text-emerald-600 dark:text-emerald-400">
                <span>Total Order Value:</span>
                <span className="text-lg font-black">₱{selectedOrder.totalAmount.toLocaleString()}</span>
              </div>
            </div>

            {/* Proof of Payment Preview */}
            <div className="mt-5">
              <h3 className="text-xs font-bold uppercase tracking-wider text-neutral-400 mb-2">
                Payment Proof Attachment
              </h3>
              {selectedOrder.proofImagePath ? (
                <div className="p-3 rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-neutral-50 dark:bg-neutral-900/50">
                  <div className="flex items-center space-x-2 text-xs font-semibold text-emerald-600 dark:text-emerald-400 mb-2">
                    <CheckCircle2 className="w-4 h-4" />
                    <span>Proof of Payment Uploaded by Branch</span>
                  </div>
                  <div className="rounded-xl overflow-hidden max-h-56 bg-neutral-950 border border-neutral-700/50 flex items-center justify-center">
                    <img
                      src={selectedOrder.proofImagePath}
                      alt="Proof of Payment"
                      className="max-h-56 w-full object-contain"
                    />
                  </div>
                </div>
              ) : (
                <div className="p-4 rounded-2xl border border-amber-500/20 bg-amber-500/5 text-xs text-amber-600 dark:text-amber-400 flex items-center space-x-2">
                  <Clock className="w-4 h-4" />
                  <span>No proof of payment uploaded yet by branch manager.</span>
                </div>
              )}
            </div>

            {/* Rejection reason display */}
            {selectedOrder.rejectionReason && (
              <div className="mt-4 p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-xs text-red-600 dark:text-red-400">
                <p className="font-bold">Rejection Note:</p>
                <p className="mt-0.5">{selectedOrder.rejectionReason}</p>
              </div>
            )}

            {/* Modal Actions */}
            <div className="mt-6 pt-4 border-t border-neutral-200 dark:border-neutral-800 flex flex-wrap items-center justify-between gap-3">
              <button
                onClick={() => {
                  deleteOrder(selectedOrder.id);
                  setSelectedOrder(null);
                }}
                className="text-xs text-red-500 hover:underline font-semibold"
              >
                Delete Order
              </button>

              <div className="flex flex-wrap items-center gap-2">
                {selectedOrder.status !== 'approved' && (
                  <>
                    <button
                      onClick={() => setShowRejectModal(true)}
                      className="px-3.5 py-2 text-xs font-bold rounded-xl border border-red-500/30 text-red-600 dark:text-red-400 hover:bg-red-500/10 transition-colors"
                    >
                      Reject Order
                    </button>
                    <button
                      onClick={() => handleApprove(selectedOrder.id)}
                      className="px-4 py-2 text-xs font-bold rounded-xl bg-emerald-600 text-white hover:bg-emerald-700 shadow-sm transition-colors flex items-center space-x-1.5"
                    >
                      <CheckCircle2 className="w-4 h-4" />
                      <span>Approve & Release Stock</span>
                    </button>
                  </>
                )}

                {selectedOrder.status === 'approved' && (
                  <button
                    onClick={() => {
                      setDeliveryAddress(`${selectedOrder.branchName} Station`);
                      setShowDeliveryModal(true);
                    }}
                    className="px-4 py-2 text-xs font-bold rounded-xl bg-[#F37021] text-white hover:bg-[#d85e15] shadow-sm transition-colors flex items-center space-x-1.5"
                  >
                    <Truck className="w-4 h-4" />
                    <span>Create Delivery Dispatch</span>
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Reject Order Reason Modal */}
      {showRejectModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4">
          <div className={`w-full max-w-md rounded-3xl p-6 shadow-2xl border ${
            isDark ? 'bg-[#1c1c1c] border-neutral-700 text-white' : 'bg-white border-neutral-200 text-neutral-900'
          }`}>
            <h3 className="text-base font-bold">Reject Order</h3>
            <p className="text-xs text-neutral-500 mt-1">
              Provide a reason to notify the branch manager (e.g., Unclear receipt, insufficient stock).
            </p>
            <form onSubmit={handleRejectSubmit} className="mt-4 space-y-4">
              <textarea
                required
                rows={3}
                value={rejectionReason}
                onChange={(e) => setRejectionReason(e.target.value)}
                placeholder="Reason for order rejection..."
                className={`w-full p-3 rounded-xl text-xs border focus:outline-none focus:ring-2 focus:ring-red-500 ${
                  isDark
                    ? 'bg-neutral-900 border-neutral-700 text-white'
                    : 'bg-neutral-50 border-neutral-200 text-neutral-900'
                }`}
              />
              <div className="flex items-center justify-end space-x-2">
                <button
                  type="button"
                  onClick={() => setShowRejectModal(false)}
                  className="px-3 py-2 text-xs font-medium rounded-xl border border-neutral-300 dark:border-neutral-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 text-xs font-bold rounded-xl bg-red-600 text-white hover:bg-red-700"
                >
                  Confirm Rejection
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Create Delivery Dispatch Modal */}
      {showDeliveryModal && selectedOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4">
          <div className={`w-full max-w-md rounded-3xl p-6 shadow-2xl border ${
            isDark ? 'bg-[#1c1c1c] border-neutral-700 text-white' : 'bg-white border-neutral-200 text-neutral-900'
          }`}>
            <div className="flex items-center space-x-2 text-[#F37021] mb-2">
              <Truck className="w-5 h-5" />
              <h3 className="text-base font-bold">Dispatch Delivery</h3>
            </div>
            <p className="text-xs text-neutral-500">
              Schedule delivery for approved order #{selectedOrder.id} to {selectedOrder.branchName}.
            </p>

            <form onSubmit={handleCreateDeliverySubmit} className="mt-4 space-y-3 text-xs">
              <div>
                <label className="block font-bold uppercase tracking-wider text-neutral-400 mb-1">
                  Courier / Logistics Partner
                </label>
                <input
                  type="text"
                  required
                  value={courierName}
                  onChange={(e) => setCourierName(e.target.value)}
                  placeholder="e.g. LBC Express, J&T Cargo, In-House Fleet"
                  className={`w-full p-2.5 rounded-xl border focus:outline-none focus:ring-2 focus:ring-[#80C7F2] ${
                    isDark ? 'bg-neutral-900 border-neutral-700 text-white' : 'bg-neutral-50 border-neutral-200'
                  }`}
                />
              </div>

              <div>
                <label className="block font-bold uppercase tracking-wider text-neutral-400 mb-1">
                  Tracking Number / Reference
                </label>
                <input
                  type="text"
                  value={trackingNumber}
                  onChange={(e) => setTrackingNumber(e.target.value)}
                  placeholder="e.g. PH-LBC-849204"
                  className={`w-full p-2.5 rounded-xl border focus:outline-none focus:ring-2 focus:ring-[#80C7F2] ${
                    isDark ? 'bg-neutral-900 border-neutral-700 text-white' : 'bg-neutral-50 border-neutral-200'
                  }`}
                />
              </div>

              <div>
                <label className="block font-bold uppercase tracking-wider text-neutral-400 mb-1">
                  Delivery Destination Address
                </label>
                <input
                  type="text"
                  required
                  value={deliveryAddress}
                  onChange={(e) => setDeliveryAddress(e.target.value)}
                  placeholder="Branch street address"
                  className={`w-full p-2.5 rounded-xl border focus:outline-none focus:ring-2 focus:ring-[#80C7F2] ${
                    isDark ? 'bg-neutral-900 border-neutral-700 text-white' : 'bg-neutral-50 border-neutral-200'
                  }`}
                />
              </div>

              <div>
                <label className="block font-bold uppercase tracking-wider text-neutral-400 mb-1">
                  Handling Instructions
                </label>
                <textarea
                  rows={2}
                  value={deliveryNotes}
                  onChange={(e) => setDeliveryNotes(e.target.value)}
                  placeholder="Keep dry, insulated cold container..."
                  className={`w-full p-2.5 rounded-xl border focus:outline-none focus:ring-2 focus:ring-[#80C7F2] ${
                    isDark ? 'bg-neutral-900 border-neutral-700 text-white' : 'bg-neutral-50 border-neutral-200'
                  }`}
                />
              </div>

              <div className="flex items-center justify-end space-x-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowDeliveryModal(false)}
                  className="px-3 py-2 font-medium rounded-xl border border-neutral-300 dark:border-neutral-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 font-bold rounded-xl bg-[#F37021] text-white hover:bg-[#d85e15]"
                >
                  Confirm Dispatch
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
