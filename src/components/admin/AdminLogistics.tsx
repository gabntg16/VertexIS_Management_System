import React, { useState } from 'react';
import { useData } from '../../context/DataContext';
import { Delivery, DeliveryStatus, Receiving } from '../../types';
import {
  Truck,
  PackageCheck,
  Clock,
  CheckCircle2,
  AlertOctagon,
  Search,
  ExternalLink,
  MapPin,
  Calendar,
  AlertCircle,
  FileCheck,
} from 'lucide-react';

export const AdminLogistics: React.FC = () => {
  const {
    deliveries,
    receivings,
    orders,
    updateDeliveryStatus,
    themeMode,
  } = useData();

  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDelivery, setSelectedDelivery] = useState<Delivery | null>(null);

  const isDark = themeMode === 'dark';

  const filteredDeliveries = deliveries.filter((d) => {
    const matchesStatus = filterStatus === 'all' ? true : d.status === filterStatus;
    const matchesSearch =
      d.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      d.address.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (d.courierName && d.courierName.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (d.trackingNumber && d.trackingNumber.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchesStatus && matchesSearch;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black tracking-tight">Logistics & Outbound Shipments</h1>
          <p className="text-xs text-neutral-500 font-medium">
            Track deliveries dispatched from Bicol Commissary to 19 branches and inspect receiving condition reports.
          </p>
        </div>

        {/* Status Filter */}
        <div className="flex items-center space-x-1.5 overflow-x-auto pb-1">
          {[
            { id: 'all', label: 'All Dispatches' },
            { id: 'inTransit', label: 'In Transit' },
            { id: 'pending', label: 'Pending' },
            { id: 'delivered', label: 'Delivered' },
          ].map((f) => (
            <button
              key={f.id}
              onClick={() => setFilterStatus(f.id)}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                filterStatus === f.id
                  ? 'bg-[#F37021] text-white'
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
          placeholder="Search by tracking code, courier, or branch address..."
          className={`w-full pl-10 pr-4 py-2.5 rounded-xl text-sm border focus:outline-none focus:ring-2 focus:ring-[#80C7F2] ${
            isDark
              ? 'bg-[#161616] border-neutral-800 text-white placeholder-neutral-500'
              : 'bg-white border-neutral-200 text-neutral-900 placeholder-neutral-400'
          }`}
        />
      </div>

      {/* Deliveries List */}
      <div className="space-y-3">
        {filteredDeliveries.length === 0 ? (
          <div className={`p-12 text-center rounded-3xl border ${
            isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-neutral-200'
          }`}>
            <Truck className="w-12 h-12 text-neutral-400 mx-auto mb-3 opacity-60" />
            <p className="text-sm font-bold">No deliveries found</p>
            <p className="text-xs text-neutral-500 mt-1">
              Deliveries are created when branch stock orders are approved.
            </p>
          </div>
        ) : (
          filteredDeliveries.map((del) => {
            const relOrder = orders.find((o) => o.id === del.orderId);
            const relReceiving = receivings.find((r) => r.deliveryId === del.id);

            return (
              <div
                key={del.id}
                className={`p-5 rounded-2xl border transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4 ${
                  isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-neutral-200 shadow-xs'
                }`}
              >
                <div className="space-y-2">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="font-extrabold text-sm">{del.courierName || 'Courier'}</span>
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
                      {del.status === 'inTransit' ? '🚚 In Transit' : del.status}
                    </span>
                  </div>

                  <div className="text-xs text-neutral-500 flex flex-wrap items-center gap-x-3 gap-y-1">
                    <span className="flex items-center space-x-1">
                      <MapPin className="w-3.5 h-3.5" />
                      <span>{del.address}</span>
                    </span>
                    <span>•</span>
                    <span>Order #{del.orderId}</span>
                    {relOrder && <span>({relOrder.branchName})</span>}
                  </div>

                  {del.notes && (
                    <p className="text-[11px] text-neutral-400 italic">
                      Note: {del.notes}
                    </p>
                  )}

                  {/* Inspection Status Badge */}
                  {relReceiving && (
                    <div className="pt-1 flex items-center space-x-2">
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-md flex items-center space-x-1 ${
                        relReceiving.status === 'received'
                          ? 'bg-emerald-500/10 text-emerald-600'
                          : relReceiving.status === 'damaged'
                          ? 'bg-red-500/10 text-red-600'
                          : relReceiving.status === 'returned'
                          ? 'bg-purple-500/10 text-purple-600'
                          : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-400'
                      }`}>
                        <FileCheck className="w-3 h-3" />
                        <span>Branch Inspection: {relReceiving.status.toUpperCase()}</span>
                      </span>
                      {relReceiving.receiverName && (
                        <span className="text-[10px] text-neutral-400">
                          (Signed: {relReceiving.receiverName})
                        </span>
                      )}
                    </div>
                  )}
                </div>

                <div className="flex items-center space-x-2 self-end sm:self-auto">
                  <select
                    value={del.status}
                    onChange={(e) => updateDeliveryStatus(del.id, e.target.value as DeliveryStatus)}
                    className={`text-xs font-bold p-2 rounded-xl border ${
                      isDark ? 'bg-neutral-900 border-neutral-700 text-white' : 'bg-neutral-50 border-neutral-200'
                    }`}
                  >
                    <option value="pending">Pending</option>
                    <option value="inTransit">In Transit</option>
                    <option value="delivered">Delivered</option>
                    <option value="canceled">Canceled</option>
                  </select>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};
