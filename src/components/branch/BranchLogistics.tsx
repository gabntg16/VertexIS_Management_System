import React, { useState } from 'react';
import { useData } from '../../context/DataContext';
import { Delivery, ReceivingStatus } from '../../types';
import {
  Truck,
  PackageCheck,
  CheckCircle2,
  AlertTriangle,
  FileCheck,
  Calendar,
  Clock,
  RotateCcw,
} from 'lucide-react';

export const BranchLogistics: React.FC = () => {
  const {
    currentBranch,
    deliveries,
    receivings,
    orders,
    createReceivingInspection,
    themeMode,
  } = useData();

  const [selectedDeliveryForInspect, setSelectedDeliveryForInspect] = useState<Delivery | null>(null);
  const [inspectStatus, setInspectStatus] = useState<ReceivingStatus>('received');
  const [receiverName, setReceiverName] = useState('');
  const [inspectNotes, setInspectNotes] = useState('');

  if (!currentBranch) return null;

  const branchId = currentBranch.id;
  const isDark = themeMode === 'dark';

  // Find deliveries whose order belongs to this branch
  const branchOrders = orders.filter((o) => o.branchId === branchId);
  const branchOrderIds = new Set(branchOrders.map((o) => o.id));
  const branchDeliveries = deliveries.filter((d) => branchOrderIds.has(d.orderId));

  const handleInspectSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedDeliveryForInspect || !receiverName.trim()) return;
    createReceivingInspection(
      selectedDeliveryForInspect.id,
      selectedDeliveryForInspect.orderId,
      inspectStatus,
      receiverName.trim(),
      inspectNotes.trim()
    );
    setSelectedDeliveryForInspect(null);
    setReceiverName('');
    setInspectNotes('');
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-black tracking-tight">Inbound Shipments & Receiving</h1>
        <p className="text-xs text-neutral-500 font-medium">
          Track dispatches sent from the Bicol commissary and inspect incoming stock conditions upon arrival.
        </p>
      </div>

      {/* Shipments List */}
      <div className="space-y-3">
        {branchDeliveries.length === 0 ? (
          <div className={`p-12 text-center rounded-3xl border ${
            isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-neutral-200'
          }`}>
            <Truck className="w-12 h-12 text-neutral-400 mx-auto mb-3 opacity-60" />
            <p className="text-sm font-bold">No active dispatches for your branch</p>
            <p className="text-xs text-neutral-500 mt-1">
              When you submit a stock order and HQ approves it, tracking information will appear here.
            </p>
          </div>
        ) : (
          branchDeliveries.map((del) => {
            const relOrder = orders.find((o) => o.id === del.orderId);
            const relReceiving = receivings.find((r) => r.deliveryId === del.id);

            return (
              <div
                key={del.id}
                className={`p-5 rounded-2xl border transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4 ${
                  isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-neutral-200 shadow-xs'
                }`}
              >
                <div className="space-y-1.5">
                  <div className="flex items-center space-x-2.5">
                    <span className="font-extrabold text-sm">{del.courierName || 'LBC Express'}</span>
                    <span className="text-xs font-mono px-2 py-0.5 rounded-md bg-neutral-100 dark:bg-neutral-800 text-neutral-500">
                      {del.trackingNumber || del.id}
                    </span>
                    <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                      del.status === 'delivered'
                        ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400'
                        : del.status === 'inTransit'
                        ? 'bg-[#80C7F2]/20 text-[#1a7bb5] dark:text-[#80C7F2]'
                        : 'bg-amber-500/15 text-amber-600'
                    }`}>
                      {del.status === 'inTransit' ? '🚚 In Transit to Branch' : del.status}
                    </span>
                  </div>

                  <p className="text-xs text-neutral-600 dark:text-neutral-300">
                    Order #{del.orderId} • {relOrder?.items.map((i) => `${i.quantity}x ${i.productName}`).join(', ')}
                  </p>

                  {/* Inspection Status Badge */}
                  {relReceiving ? (
                    <div className="flex items-center space-x-2 pt-1">
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-md flex items-center space-x-1 ${
                        relReceiving.status === 'received'
                          ? 'bg-emerald-500/10 text-emerald-600'
                          : relReceiving.status === 'damaged'
                          ? 'bg-red-500/10 text-red-600'
                          : 'bg-purple-500/10 text-purple-600'
                      }`}>
                        <FileCheck className="w-3 h-3" />
                        <span>Inspection Status: {relReceiving.status.toUpperCase()}</span>
                      </span>
                      <span className="text-[10px] text-neutral-400">
                        (Inspected by {relReceiving.receiverName} on {new Date(relReceiving.receivedAt).toLocaleDateString()})
                      </span>
                    </div>
                  ) : (
                    <span className="text-[10px] text-amber-500 font-semibold flex items-center space-x-1 pt-1">
                      <Clock className="w-3 h-3" />
                      <span>Pending branch inspection upon physical delivery</span>
                    </span>
                  )}
                </div>

                <div className="flex items-center space-x-3 self-end sm:self-auto">
                  {!relReceiving && (
                    <button
                      onClick={() => {
                        setSelectedDeliveryForInspect(del);
                        setReceiverName(currentBranch.name + ' Staff');
                      }}
                      className="px-3.5 py-2 rounded-xl bg-emerald-600 text-white text-xs font-bold hover:bg-emerald-700 transition-all flex items-center space-x-1.5 shadow-xs"
                    >
                      <PackageCheck className="w-3.5 h-3.5" />
                      <span>Inspect & Acknowledge</span>
                    </button>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Inspect / Receiving Acknowledgment Modal */}
      {selectedDeliveryForInspect && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4">
          <div className={`w-full max-w-md rounded-3xl p-6 shadow-2xl border ${
            isDark ? 'bg-[#1c1c1c] border-neutral-700 text-white' : 'bg-white border-neutral-200 text-neutral-900'
          }`}>
            <div className="flex items-center space-x-2 text-emerald-600 mb-2">
              <PackageCheck className="w-5 h-5" />
              <h3 className="text-base font-bold">Inbound Package Inspection</h3>
            </div>
            <p className="text-xs text-neutral-500">
              Verify stock quantity and package condition for Delivery {selectedDeliveryForInspect.trackingNumber || selectedDeliveryForInspect.id}.
            </p>

            <form onSubmit={handleInspectSubmit} className="mt-4 space-y-3 text-xs">
              <div>
                <label className="block font-bold uppercase tracking-wider text-neutral-400 mb-1">
                  Receiving Condition
                </label>
                <select
                  value={inspectStatus}
                  onChange={(e) => setInspectStatus(e.target.value as ReceivingStatus)}
                  className={`w-full p-2.5 rounded-xl border font-bold ${
                    isDark ? 'bg-neutral-900 border-neutral-700 text-white' : 'bg-neutral-50 border-neutral-200'
                  }`}
                >
                  <option value="received">✅ Received in Good Condition (Complete)</option>
                  <option value="damaged">⚠️ Damaged in Transit (Report to HQ)</option>
                  <option value="returned">🔄 Return to Commissary</option>
                </select>
              </div>

              <div>
                <label className="block font-bold uppercase tracking-wider text-neutral-400 mb-1">
                  Staff Receiver Name
                </label>
                <input
                  type="text"
                  required
                  value={receiverName}
                  onChange={(e) => setReceiverName(e.target.value)}
                  placeholder="e.g. Maria Santos (Branch Supervisor)"
                  className={`w-full p-2.5 rounded-xl border ${
                    isDark ? 'bg-neutral-900 border-neutral-700 text-white' : 'bg-neutral-50 border-neutral-200'
                  }`}
                />
              </div>

              <div>
                <label className="block font-bold uppercase tracking-wider text-neutral-400 mb-1">
                  Inspection Notes & Remarks
                </label>
                <textarea
                  rows={2}
                  value={inspectNotes}
                  onChange={(e) => setInspectNotes(e.target.value)}
                  placeholder="Seals intact, temperature checked..."
                  className={`w-full p-2.5 rounded-xl border ${
                    isDark ? 'bg-neutral-900 border-neutral-700 text-white' : 'bg-neutral-50 border-neutral-200'
                  }`}
                />
              </div>

              <div className="flex items-center justify-end space-x-2 pt-2">
                <button
                  type="button"
                  onClick={() => setSelectedDeliveryForInspect(null)}
                  className="px-3.5 py-2 font-medium rounded-xl border border-neutral-300 dark:border-neutral-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 font-bold rounded-xl bg-emerald-600 text-white hover:bg-emerald-700"
                >
                  Confirm & Update Stock
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
