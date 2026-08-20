import React, { useState } from 'react';
import { useData } from '../../context/DataContext';
import {
  Package,
  AlertTriangle,
  Sparkles,
  TrendingUp,
  Plus,
  Minus,
  CheckCircle2,
  Clock,
} from 'lucide-react';

export const BranchInventory: React.FC<{ onNavigateTab: (tab: string) => void }> = ({ onNavigateTab }) => {
  const {
    currentBranch,
    getInventoryForBranch,
    restockSuggestionsForBranch,
    updateStock,
    themeMode,
  } = useData();

  if (!currentBranch) return null;

  const branchId = currentBranch.id;
  const inventory = getInventoryForBranch(branchId);
  const suggestions = restockSuggestionsForBranch(branchId);
  const isDark = themeMode === 'dark';

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black tracking-tight">Branch Inventory Management</h1>
          <p className="text-xs text-neutral-500 font-medium">
            Live stock counts for all 7 gourmet marshmallow flavors and automated replenishment guidance.
          </p>
        </div>

        <button
          onClick={() => onNavigateTab('orders')}
          className="px-4 py-2.5 rounded-xl bg-[#F37021] text-white text-xs sm:text-sm font-bold shadow-md hover:bg-[#d85e15] transition-all flex items-center space-x-1.5 self-start sm:self-auto"
        >
          <Package className="w-4 h-4" />
          <span>Restock from Commissary</span>
        </button>
      </div>

      {/* Restock Suggestions Section */}
      <div className={`p-6 rounded-3xl border ${
        isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-[#80C7F2]/20 shadow-xs'
      }`}>
        <div className="flex items-center space-x-2 mb-4">
          <div className="p-2 rounded-xl bg-amber-500/10 text-amber-600">
            <AlertTriangle className="w-4 h-4" />
          </div>
          <div>
            <h2 className="text-base font-bold">Automated Restock Forecast</h2>
            <p className="text-xs text-neutral-500">Calculated from your branch's 14-day rolling sales velocity</p>
          </div>
        </div>

        {suggestions.length === 0 ? (
          <p className="text-xs text-neutral-500 py-4 text-center">
            ✓ All inventory items are currently well-stocked. No immediate reorders needed.
          </p>
        ) : (
          <div className="space-y-2.5">
            {suggestions.map((s, idx) => (
              <div
                key={idx}
                className={`p-3.5 rounded-2xl border flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs ${
                  s.urgency === 'Urgent'
                    ? 'bg-red-500/5 border-red-500/20'
                    : s.urgency === 'Review'
                    ? 'bg-amber-500/5 border-amber-500/20'
                    : 'bg-neutral-50 dark:bg-neutral-900 border-neutral-200 dark:border-neutral-800'
                }`}
              >
                <div>
                  <div className="flex items-center space-x-2">
                    <span className="font-extrabold text-sm text-neutral-900 dark:text-white">
                      {s.productName}
                    </span>
                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                      s.urgency === 'Urgent'
                        ? 'bg-red-500/15 text-red-600 dark:text-red-400'
                        : s.urgency === 'Review'
                        ? 'bg-amber-500/15 text-amber-600 dark:text-amber-400'
                        : 'bg-blue-500/15 text-blue-600 dark:text-blue-400'
                    }`}>
                      {s.urgency} Priority
                    </span>
                  </div>
                  <p className="text-neutral-500 mt-1">
                    Current Stock: <strong className="text-neutral-900 dark:text-white">{s.currentStock} units</strong> • Expected 7-Day Demand: <strong>{Math.ceil(s.expectedWeeklyDemand)} units</strong>
                  </p>
                </div>

                <div className="flex items-center space-x-3 self-end sm:self-auto">
                  <div className="text-right">
                    <p className="font-black text-sm text-[#F37021]">+{s.suggestedOrderQuantity} units</p>
                    <p className="text-[10px] text-neutral-400">suggested order</p>
                  </div>
                  <button
                    onClick={() => onNavigateTab('orders')}
                    className="px-3 py-1.5 rounded-xl bg-[#F37021] text-white text-xs font-bold hover:bg-[#d85e15] shadow-xs"
                  >
                    Reorder
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Flavor Stock Table */}
      <div className={`p-6 rounded-3xl border ${
        isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-[#80C7F2]/20 shadow-xs'
      }`}>
        <h2 className="text-base font-bold mb-4">Flavor Inventory Ledger</h2>

        <div className="space-y-3">
          {inventory.map((item) => (
            <div
              key={item.id}
              className={`p-4 rounded-2xl border flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs ${
                isDark ? 'bg-neutral-900/60 border-neutral-800' : 'bg-neutral-50/70 border-neutral-200'
              }`}
            >
              <div>
                <p className="font-black text-sm text-neutral-900 dark:text-white">
                  {item.productName}
                </p>
                <p className="text-[11px] text-neutral-400 mt-0.5">
                  Artisanal Recipe • ₱149 SRP
                </p>
              </div>

              <div className="flex items-center space-x-4 self-end sm:self-auto">
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => updateStock(item.id, Math.max(0, item.stock - 1))}
                    className="w-8 h-8 rounded-xl border border-neutral-300 dark:border-neutral-700 flex items-center justify-center font-bold hover:bg-neutral-200 dark:hover:bg-neutral-800"
                    title="Deduct 1 unit"
                  >
                    <Minus className="w-3.5 h-3.5" />
                  </button>
                  <span className="w-12 text-center font-black text-base text-neutral-900 dark:text-white">
                    {item.stock}
                  </span>
                  <button
                    onClick={() => updateStock(item.id, item.stock + 1)}
                    className="w-8 h-8 rounded-xl border border-neutral-300 dark:border-neutral-700 flex items-center justify-center font-bold hover:bg-neutral-200 dark:hover:bg-neutral-800"
                    title="Add 1 unit"
                  >
                    <Plus className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
