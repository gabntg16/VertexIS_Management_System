import React, { useState, useMemo } from 'react';
import { useData } from '../../context/DataContext';
import {
  DollarSign,
  Search,
  Filter,
  Download,
  Calendar,
  Package,
  TrendingUp,
  Store,
  FileSpreadsheet,
} from 'lucide-react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  PieChart,
  Pie,
  Cell,
} from 'recharts';

export const AdminSalesHistory: React.FC = () => {
  const { sales, branches, products, themeMode } = useData();

  const [selectedBranchId, setSelectedBranchId] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');

  const isDark = themeMode === 'dark';

  // Filtered Sales List
  const filteredSales = useMemo(() => {
    return sales.filter((s) => {
      const matchesBranch = selectedBranchId === 'all' ? true : s.branchId === selectedBranchId;
      const matchesSearch =
        s.productName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (s.receiptPath && s.receiptPath.toLowerCase().includes(searchQuery.toLowerCase()));
      return matchesBranch && matchesSearch;
    });
  }, [sales, selectedBranchId, searchQuery]);

  // Flavor Popularity Analytics
  const flavorStats = useMemo(() => {
    const map: Record<string, { flavor: string; units: number; revenue: number }> = {};
    products.forEach((p) => {
      map[p.id] = { flavor: p.flavor, units: 0, revenue: 0 };
    });

    sales.forEach((s) => {
      if (map[s.productId]) {
        map[s.productId].units += s.quantity;
        map[s.productId].revenue += s.total;
      }
    });

    return Object.values(map).sort((a, b) => b.revenue - a.revenue);
  }, [sales, products]);

  const COLORS = ['#80C7F2', '#F37021', '#10B981', '#F59E0B', '#8B5CF6', '#EC4899', '#3B82F6'];

  const handleExportCSV = () => {
    const headers = ['Sale ID', 'Branch ID', 'Product', 'Quantity', 'Total (PHP)', 'Date', 'Receipt'];
    const rows = filteredSales.map((s) => [
      s.id,
      s.branchId,
      `"${s.productName.replace(/"/g, '""')}"`,
      s.quantity,
      s.total,
      s.date,
      s.receiptPath || '',
    ]);

    const csvContent =
      'data:text/csv;charset=utf-8,' +
      [headers.join(','), ...rows.map((e) => e.join(','))].join('\n');

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `marsh_bites_sales_report_${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const totalFilteredRevenue = filteredSales.reduce((sum, s) => sum + s.total, 0);
  const totalFilteredUnits = filteredSales.reduce((sum, s) => sum + s.quantity, 0);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black tracking-tight">Sales Analytics & Transaction Ledger</h1>
          <p className="text-xs text-neutral-500 font-medium">
            Historical audit log of all gourmet marshmallow retail transactions recorded across branches.
          </p>
        </div>

        <button
          onClick={handleExportCSV}
          className="px-4 py-2.5 rounded-xl bg-emerald-600 text-white text-xs sm:text-sm font-bold shadow-md hover:bg-emerald-700 transition-all flex items-center space-x-1.5 self-start sm:self-auto"
        >
          <FileSpreadsheet className="w-4 h-4" />
          <span>Export CSV Report</span>
        </button>
      </div>

      {/* Analytics Breakdown Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Flavor Revenue Breakdown */}
        <div className={`lg:col-span-2 p-6 rounded-3xl border ${
          isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-[#80C7F2]/20'
        }`}>
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-base font-bold">Flavor Sales Revenue</h2>
              <p className="text-xs text-neutral-500">Comparative revenue by handcrafted marshmallow recipe</p>
            </div>
          </div>

          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={flavorStats} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke={isDark ? '#262626' : '#e5e7eb'} />
                <XAxis type="number" stroke={isDark ? '#888' : '#666'} fontSize={11} tickFormatter={(v) => `₱${v}`} />
                <YAxis dataKey="flavor" type="category" stroke={isDark ? '#888' : '#666'} fontSize={10} width={130} />
                <Tooltip
                  formatter={(val: any) => [`₱${Number(val || 0).toLocaleString()}`, 'Revenue']}
                  contentStyle={{
                    backgroundColor: isDark ? '#1f1f1f' : '#ffffff',
                    borderColor: isDark ? '#333' : '#e5e7eb',
                    borderRadius: '12px',
                    fontSize: '12px',
                  }}
                />
                <Bar dataKey="revenue" fill="#80C7F2" radius={[0, 8, 8, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Volume Pie Chart */}
        <div className={`p-6 rounded-3xl border ${
          isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-[#80C7F2]/20'
        }`}>
          <h2 className="text-base font-bold">Flavor Share by Units</h2>
          <p className="text-xs text-neutral-500 mb-4">Volume distribution across recipes</p>

          <div className="h-52 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={flavorStats}
                  dataKey="units"
                  nameKey="flavor"
                  cx="50%"
                  cy="50%"
                  outerRadius={75}
                  innerRadius={45}
                  paddingAngle={3}
                >
                  {flavorStats.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip
                  formatter={(val: any) => [`${val} units`, 'Units Sold']}
                  contentStyle={{
                    backgroundColor: isDark ? '#1f1f1f' : '#ffffff',
                    borderColor: isDark ? '#333' : '#e5e7eb',
                    borderRadius: '12px',
                    fontSize: '12px',
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>

          <div className="grid grid-cols-2 gap-1 mt-2 text-[10px] text-neutral-500">
            {flavorStats.slice(0, 4).map((f, i) => (
              <div key={i} className="flex items-center space-x-1.5 truncate">
                <span className="w-2 h-2 rounded-full flex-shrink-0" style={{ backgroundColor: COLORS[i] }} />
                <span className="truncate">{f.flavor}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="sm:w-64">
          <select
            value={selectedBranchId}
            onChange={(e) => setSelectedBranchId(e.target.value)}
            className={`w-full p-2.5 rounded-xl border text-xs font-semibold ${
              isDark ? 'bg-[#161616] border-neutral-800 text-white' : 'bg-white border-neutral-200'
            }`}
          >
            <option value="all">All 19 Branches</option>
            {branches.map((b) => (
              <option key={b.id} value={b.id}>
                {b.name}
              </option>
            ))}
          </select>
        </div>

        <div className="relative flex-1">
          <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-neutral-400">
            <Search className="w-4 h-4" />
          </div>
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by flavor name or receipt code..."
            className={`w-full pl-10 pr-4 py-2.5 rounded-xl text-sm border focus:outline-none focus:ring-2 focus:ring-[#80C7F2] ${
              isDark
                ? 'bg-[#161616] border-neutral-800 text-white placeholder-neutral-500'
                : 'bg-white border-neutral-200 text-neutral-900 placeholder-neutral-400'
            }`}
          />
        </div>
      </div>

      {/* Totals Banner */}
      <div className={`p-4 rounded-2xl border flex flex-wrap items-center justify-between gap-3 text-xs ${
        isDark ? 'bg-neutral-900/60 border-neutral-800' : 'bg-sky-50/60 border-[#80C7F2]/20'
      }`}>
        <span className="font-semibold text-neutral-500">
          Showing {filteredSales.length} recorded sales transactions
        </span>
        <div className="flex items-center space-x-4">
          <span>
            Units Sold: <strong className="text-neutral-900 dark:text-white">{totalFilteredUnits}</strong>
          </span>
          <span>
            Total Value:{' '}
            <strong className="text-emerald-600 dark:text-emerald-400 text-sm font-black">
              ₱{totalFilteredRevenue.toLocaleString()}
            </strong>
          </span>
        </div>
      </div>

      {/* Transactions Table */}
      <div className={`rounded-3xl border overflow-hidden ${
        isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-neutral-200'
      }`}>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className={`border-b font-bold uppercase tracking-wider text-neutral-400 ${
              isDark ? 'bg-neutral-900/80 border-neutral-800' : 'bg-neutral-50 border-neutral-200'
            }`}>
              <tr>
                <th className="py-3.5 px-4">Receipt / Date</th>
                <th className="py-3.5 px-4">Branch</th>
                <th className="py-3.5 px-4">Flavor Item</th>
                <th className="py-3.5 px-4 text-center">Qty</th>
                <th className="py-3.5 px-4 text-right">Total Amount</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100 dark:divide-neutral-800/60">
              {filteredSales.slice(0, 50).map((sale) => {
                const branch = branches.find((b) => b.id === sale.branchId);
                return (
                  <tr
                    key={sale.id}
                    className="hover:bg-neutral-50 dark:hover:bg-neutral-800/40 transition-colors"
                  >
                    <td className="py-3 px-4">
                      <p className="font-mono font-bold text-neutral-900 dark:text-white">
                        {sale.receiptPath || sale.id}
                      </p>
                      <p className="text-[11px] text-neutral-400">
                        {new Date(sale.date).toLocaleString()}
                      </p>
                    </td>
                    <td className="py-3 px-4 font-semibold">
                      {branch ? branch.name : sale.branchId}
                    </td>
                    <td className="py-3 px-4 font-medium text-neutral-700 dark:text-neutral-300">
                      {sale.productName}
                    </td>
                    <td className="py-3 px-4 text-center font-bold">
                      {sale.quantity}
                    </td>
                    <td className="py-3 px-4 text-right font-black text-emerald-600 dark:text-emerald-400">
                      ₱{sale.total.toLocaleString()}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
