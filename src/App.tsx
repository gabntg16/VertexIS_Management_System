import React, { useState, useEffect } from 'react';
import { DataProvider, useData } from './context/DataContext';
import { Navbar } from './components/Navbar';
import { LoginScreen } from './components/LoginScreen';

// Admin Views
import { AdminDashboard } from './components/admin/AdminDashboard';
import { AdminOrders } from './components/admin/AdminOrders';
import { AdminProduction } from './components/admin/AdminProduction';
import { AdminBranches } from './components/admin/AdminBranches';
import { AdminLogistics } from './components/admin/AdminLogistics';
import { AdminSalesHistory } from './components/admin/AdminSalesHistory';
import { AdminCalendar } from './components/admin/AdminCalendar';
import { AdminAnnouncements } from './components/admin/AdminAnnouncements';

// Branch Views
import { BranchDashboard } from './components/branch/BranchDashboard';
import { BranchSalesPOS } from './components/branch/BranchSalesPOS';
import { BranchOrders } from './components/branch/BranchOrders';
import { BranchInventory } from './components/branch/BranchInventory';
import { BranchLogistics } from './components/branch/BranchLogistics';
import { BranchHistory } from './components/branch/BranchHistory';
import { BranchCalendar } from './components/branch/BranchCalendar';
import { BranchAnnouncements } from './components/branch/BranchAnnouncements';

const MainShell: React.FC = () => {
  const { currentUser, themeMode } = useData();
  const [activeTab, setActiveTab] = useState<string>('dashboard');

  // Reset tab to dashboard on role switch or user change
  useEffect(() => {
    setActiveTab('dashboard');
  }, [currentUser?.role, currentUser?.branchId]);

  if (!currentUser) {
    return <LoginScreen />;
  }

  const isAdmin = currentUser.role === 'admin';

  return (
    <div className={`min-h-screen transition-colors duration-200 ${
      themeMode === 'dark' ? 'bg-[#101010] text-[#f2f2f2]' : 'bg-[#F9FBFC] text-neutral-900'
    }`}>
      {/* Top Navigation */}
      <Navbar activeTab={activeTab} setActiveTab={setActiveTab} />

      {/* Main Content Area */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8">
        {isAdmin ? (
          <>
            {activeTab === 'dashboard' && <AdminDashboard onNavigateTab={setActiveTab} />}
            {activeTab === 'orders' && <AdminOrders />}
            {activeTab === 'production' && <AdminProduction />}
            {activeTab === 'branches' && <AdminBranches />}
            {activeTab === 'logistics' && <AdminLogistics />}
            {activeTab === 'sales' && <AdminSalesHistory />}
            {activeTab === 'calendar' && <AdminCalendar />}
            {activeTab === 'announcements' && <AdminAnnouncements />}
          </>
        ) : (
          <>
            {activeTab === 'dashboard' && <BranchDashboard onNavigateTab={setActiveTab} />}
            {activeTab === 'sales_pos' && <BranchSalesPOS />}
            {activeTab === 'orders' && <BranchOrders />}
            {activeTab === 'inventory' && <BranchInventory onNavigateTab={setActiveTab} />}
            {activeTab === 'logistics' && <BranchLogistics />}
            {activeTab === 'history' && <BranchHistory />}
            {activeTab === 'calendar' && <BranchCalendar />}
            {activeTab === 'announcements' && <BranchAnnouncements />}
          </>
        )}
      </main>

      {/* Modern Compact Footer */}
      <footer className="border-t border-neutral-200/60 dark:border-neutral-800/80 py-6 mt-12 text-center text-xs text-neutral-400">
        <div className="max-w-7xl mx-auto px-4 flex flex-col sm:flex-row items-center justify-between gap-2">
          <p>
            <strong>VertexIS</strong> • Marsh Bites Gourmet Marshmallow Enterprise System
          </p>
          <p className="text-[11px]">
            Commissary: Naga City, Bicol • 19 Nationwide Franchise Branches
          </p>
        </div>
      </footer>
    </div>
  );
};

export function App() {
  return (
    <DataProvider>
      <MainShell />
    </DataProvider>
  );
}

export default App;
