import React, { useState } from 'react';
import { useData } from '../context/DataContext';
import { SystemIntegrityTester } from './admin/SystemIntegrityTester';
import {
  Store,
  ShieldCheck,
  Sun,
  Moon,
  LogOut,
  RotateCcw,
  UserCheck,
  ChevronDown,
  MapPin,
  LayoutDashboard,
  ShoppingBag,
  ChefHat,
  Building2,
  Truck,
  TrendingUp,
  Calendar,
  Megaphone,
  CreditCard,
  Boxes,
  Receipt,
  PackageCheck,
  CloudCheck,
  CloudOff,
  RefreshCw,
  FlaskConical,
  Menu,
  X,
} from 'lucide-react';

interface NavbarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

export const Navbar: React.FC<NavbarProps> = ({ activeTab, setActiveTab }) => {
  const {
    currentUser,
    users,
    currentBranch,
    themeMode,
    syncState,
    toggleTheme,
    switchUser,
    logout,
    resetToDefaultData,
    forceSyncCloud,
    pendingOrdersCount,
    deliveries,
    orders,
  } = useData();

  // Navigation and Modal States
  const [showUserMenu, setShowUserMenu] = useState(false);
  const [showConfirmReset, setShowConfirmReset] = useState(false);
  const [showTesterModal, setShowTesterModal] = useState(false);
  const [isManualSyncing, setIsManualSyncing] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  if (!currentUser) return null;

  const isAdmin = currentUser.role === 'admin';

  const handleManualSync = async () => {
    try {
      setIsManualSyncing(true);
      await forceSyncCloud();
    } finally {
      setTimeout(() => setIsManualSyncing(false), 600);
    }
  };

  // Calculate badge counts
  const branchInTransitCount = !isAdmin && currentBranch
    ? deliveries.filter((d) => {
        const order = orders.find((o) => o.id === d.orderId);
        return order?.branchId === currentBranch.id && d.status === 'inTransit';
      }).length
    : 0;

  const adminTabs = [
    { id: 'dashboard', label: 'Overview', icon: LayoutDashboard },
    {
      id: 'orders',
      label: 'Orders & Approvals',
      icon: ShoppingBag,
      badge: pendingOrdersCount > 0 ? pendingOrdersCount : undefined,
      badgeColor: 'bg-[#F37021] text-white',
    },
    { id: 'production', label: 'Commissary Batching', icon: ChefHat },
    { id: 'branches', label: '19 Branches', icon: Building2 },
    { id: 'logistics', label: 'Fleet & Dispatch', icon: Truck },
    { id: 'sales', label: 'Sales Analytics', icon: TrendingUp },
    { id: 'calendar', label: 'Schedule', icon: Calendar },
    { id: 'announcements', label: 'Announcements', icon: Megaphone },
  ];

  const branchTabs = [
    { id: 'dashboard', label: 'Overview', icon: LayoutDashboard },
    { id: 'sales_pos', label: 'POS Register', icon: CreditCard },
    { id: 'orders', label: 'Order Stock', icon: ShoppingBag },
    { id: 'inventory', label: 'Inventory', icon: Boxes },
    {
      id: 'logistics',
      label: 'Inbound Deliveries',
      icon: PackageCheck,
      badge: branchInTransitCount > 0 ? branchInTransitCount : undefined,
      badgeColor: 'bg-[#80C7F2] text-neutral-900',
    },
    { id: 'history', label: 'Sales Records', icon: Receipt },
    { id: 'calendar', label: 'Schedule', icon: Calendar },
    { id: 'announcements', label: 'Bulletins', icon: Megaphone },
  ];

  const tabs = isAdmin ? adminTabs : branchTabs;

  const handleTabClick = (tabId: string) => {
    setActiveTab(tabId);
    setIsMobileMenuOpen(false);
  };

  return (
    <header className="sticky top-0 z-40 border-b border-neutral-200/80 dark:border-neutral-800 bg-white/95 dark:bg-[#141414]/95 backdrop-blur-md transition-colors shadow-2xs">
      {/* 
        ========================================================================
        Top Brand & Controls Row: Responsive Header (Adaptive for Mobile, Tablet, Laptop, Desktop)
        ========================================================================
      */}
      <div className="w-full max-w-7xl mx-auto px-3 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16 sm:h-18 gap-2 sm:gap-4">
          
          {/* Logo & Brand Identity (Flex shrink with min-w-0 to prevent text blowout) */}
          <div className="flex items-center space-x-2 sm:space-x-3.5 min-w-0 py-1">
            <div className="w-10 h-10 sm:w-11 sm:h-11 rounded-xl sm:rounded-2xl bg-white dark:bg-neutral-800/90 flex items-center justify-center shadow-xs overflow-hidden border border-neutral-200/90 dark:border-neutral-700/80 p-0.5 flex-shrink-0">
              <img
                src="/marshbites_logo.jpg"
                alt="The Marsh Bites Client Mascot"
                className="w-full h-full object-cover rounded-lg sm:rounded-xl"
                referrerPolicy="no-referrer"
                onError={(e) => {
                  const target = e.currentTarget;
                  if (target.src.indexOf('marshbites_mascot.jpg') === -1) {
                    target.src = '/marshbites_mascot.jpg';
                  }
                }}
              />
            </div>
            
            <div className="flex flex-col justify-center min-w-0">
              <div className="flex items-center space-x-1.5 sm:space-x-2 truncate">
                <span className="font-black tracking-tight text-lg sm:text-xl lg:text-2xl text-neutral-900 dark:text-white leading-none">
                  Vertex<span className="text-[#F37021]">IS</span>
                </span>
                <span className="text-[10px] sm:text-[11px] font-bold px-2 py-0.5 rounded-full bg-[#80C7F2]/15 text-[#0369a1] dark:bg-[#80C7F2]/25 dark:text-[#80C7F2] border border-[#80C7F2]/30 leading-none whitespace-nowrap">
                  The Marsh Bites
                </span>
              </div>
              <p className="text-[10px] sm:text-xs font-semibold text-neutral-500 dark:text-neutral-400 truncate tracking-tight leading-none mt-1">
                {isAdmin ? 'Central Commissary HQ' : `${currentBranch?.name || 'Branch'} Station`}
              </p>
            </div>
          </div>

          {/* Right Action Bar: Responsive Controls with Adaptive Mobile Display */}
          <div className="flex items-center space-x-1 sm:space-x-2 md:space-x-3 flex-shrink-0">
            
            {/* Cloud Firestore Status Badge (Icon only on mobile, text on md+) */}
            <button
              id="firestore-sync-status-btn"
              onClick={handleManualSync}
              className={`flex items-center space-x-1.5 px-2 sm:px-2.5 py-1.5 rounded-xl border text-xs font-semibold transition-all ${
                syncState.status === 'connected'
                  ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-600 dark:text-emerald-400 hover:bg-emerald-500/20'
                  : syncState.status === 'syncing' || isManualSyncing
                  ? 'bg-amber-500/10 border-amber-500/30 text-amber-600 dark:text-amber-400'
                  : 'bg-neutral-100 dark:bg-neutral-800 border-neutral-200 dark:border-neutral-700 text-neutral-500'
              }`}
              title="Firestore Cloud Database Synchronization Status. Click to force sync."
            >
              {syncState.status === 'connected' && !isManualSyncing ? (
                <>
                  <span className="relative flex h-2 w-2">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                  </span>
                  <CloudCheck className="w-3.5 h-3.5" />
                  <span className="hidden md:inline">Synced</span>
                </>
              ) : syncState.status === 'syncing' || isManualSyncing ? (
                <>
                  <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                  <span className="hidden md:inline">Syncing...</span>
                </>
              ) : (
                <>
                  <CloudOff className="w-3.5 h-3.5 text-neutral-400" />
                  <span className="hidden md:inline">Offline</span>
                </>
              )}
            </button>

            {/* Account Switcher Dropdown */}
            <div className="relative">
              <button
                id="user-switcher-btn"
                onClick={() => setShowUserMenu(!showUserMenu)}
                className={`flex items-center space-x-1 sm:space-x-1.5 px-2 sm:px-3 py-1.5 rounded-xl border text-xs sm:text-sm font-semibold transition-all shadow-xs ${
                  isAdmin
                    ? 'bg-amber-500/10 border-amber-500/30 text-amber-600 dark:text-amber-400 hover:bg-amber-500/20'
                    : 'bg-[#80C7F2]/10 border-[#80C7F2]/30 text-[#1a7bb5] dark:text-[#80C7F2] hover:bg-[#80C7F2]/20'
                }`}
                title="Switch role / branch account"
              >
                {isAdmin ? (
                  <ShieldCheck className="w-4 h-4 text-amber-500 flex-shrink-0" />
                ) : (
                  <Store className="w-4 h-4 text-[#80C7F2] flex-shrink-0" />
                )}
                <span className="hidden lg:inline-block truncate max-w-[120px] font-bold">
                  {isAdmin ? 'HQ Admin' : currentBranch?.name?.replace('Marsh Bites ', '') || currentUser.name}
                </span>
                <ChevronDown className="w-3 h-3 opacity-60" />
              </button>

              {/* User Switcher Dropdown Menu */}
              {showUserMenu && (
                <>
                  <div
                    className="fixed inset-0 z-40"
                    onClick={() => setShowUserMenu(false)}
                  />
                  <div className="absolute right-0 mt-2 w-72 max-h-96 overflow-y-auto rounded-2xl shadow-2xl border z-50 p-2 text-sm bg-white dark:bg-[#1c1c1c] border-neutral-200 dark:border-neutral-700 text-neutral-900 dark:text-white">
                    <div className="px-3 py-2 border-b border-neutral-200 dark:border-neutral-800">
                      <p className="text-[11px] font-bold uppercase tracking-wider text-neutral-400">
                        Switch Active Role / Branch
                      </p>
                      <p className="text-xs text-neutral-500 mt-0.5">
                        Test centralized multi-branch features instantly
                      </p>
                    </div>

                    <div className="py-1">
                      {users.map((u) => {
                        const isSelected = u.id === currentUser.id;
                        return (
                          <button
                            key={u.id}
                            onClick={() => {
                              switchUser(u.id);
                              setShowUserMenu(false);
                            }}
                            className={`w-full text-left px-3 py-2 rounded-xl flex items-center justify-between text-xs transition-colors ${
                              isSelected
                                ? 'bg-[#80C7F2]/20 text-[#0c5077] dark:text-[#80C7F2] font-bold'
                                : 'hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-700 dark:text-neutral-200'
                            }`}
                          >
                            <div className="flex items-center space-x-2 truncate">
                              {u.role === 'admin' ? (
                                <ShieldCheck className="w-3.5 h-3.5 text-amber-500 flex-shrink-0" />
                              ) : (
                                <MapPin className="w-3.5 h-3.5 text-[#80C7F2] flex-shrink-0" />
                              )}
                              <span className="truncate">{u.name}</span>
                            </div>
                            {isSelected && <UserCheck className="w-3.5 h-3.5 text-[#80C7F2]" />}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </>
              )}
            </div>

            {/* Security & Integrity Test Suite Diagnostics Button */}
            <button
              id="security-test-suite-btn"
              onClick={() => setShowTesterModal(true)}
              className="flex items-center space-x-1 sm:space-x-1.5 px-2 sm:px-2.5 py-1.5 rounded-xl border text-xs font-semibold transition-all bg-emerald-500/10 border-emerald-500/30 text-emerald-600 dark:text-emerald-400 hover:bg-emerald-500/20"
              title="Open System Security & Test Suite"
            >
              <FlaskConical className="w-3.5 h-3.5 flex-shrink-0" />
              <span className="hidden xl:inline">Security Tests</span>
            </button>

            {/* Dark/Light Mode Toggle */}
            <button
              id="theme-toggle-btn"
              onClick={toggleTheme}
              className="p-1.5 sm:p-2 rounded-xl border transition-colors bg-neutral-100 dark:bg-neutral-800 border-neutral-200 dark:border-neutral-700 text-neutral-700 dark:text-amber-300 hover:bg-neutral-200 dark:hover:bg-neutral-700"
              title={themeMode === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
            >
              {themeMode === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>

            {/* Reset Database Button */}
            <button
              id="reset-db-btn"
              onClick={() => setShowConfirmReset(true)}
              className="p-1.5 sm:p-2 rounded-xl border transition-colors bg-neutral-100 dark:bg-neutral-800 border-neutral-200 dark:border-neutral-700 text-neutral-500 hover:text-red-500 dark:hover:text-red-400 hover:bg-red-50 dark:hover:bg-red-500/10"
              title="Reset Sample Data"
            >
              <RotateCcw className="w-4 h-4" />
            </button>

            {/* Log Out Button */}
            <button
              id="logout-btn"
              onClick={logout}
              className="p-1.5 sm:p-2 rounded-xl border transition-colors bg-neutral-100 dark:bg-neutral-800 border-neutral-200 dark:border-neutral-700 text-neutral-500 hover:text-neutral-900 dark:hover:text-white hover:bg-neutral-200 dark:hover:bg-neutral-700"
              title="Log Out"
            >
              <LogOut className="w-4 h-4" />
            </button>

            {/* Mobile / Tablet Hamburger Toggle Button */}
            <button
              id="mobile-menu-toggle-btn"
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              className="p-1.5 sm:p-2 rounded-xl border transition-colors bg-neutral-100 dark:bg-neutral-800 border-neutral-200 dark:border-neutral-700 text-neutral-700 dark:text-neutral-200 hover:bg-neutral-200 dark:hover:bg-neutral-700 lg:hidden"
              title="Toggle Navigation Menu"
            >
              {isMobileMenuOpen ? <X className="w-4 h-4" /> : <Menu className="w-4 h-4" />}
            </button>
          </div>
        </div>
      </div>

      {/* 
        ========================================================================
        Primary Navigation: Scrollable Horizontal Tab Bar (with touch drag and responsive gap)
        ========================================================================
      */}
      <div className="border-t border-neutral-200/80 dark:border-neutral-800 bg-neutral-50/90 dark:bg-neutral-900/90 px-3 sm:px-6 lg:px-8 overflow-x-auto scrollbar-thin">
        <div className="w-full max-w-7xl mx-auto flex items-center space-x-1 sm:space-x-1.5 py-1.5 sm:py-2 min-w-max">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                id={`nav-tab-${tab.id}`}
                onClick={() => handleTabClick(tab.id)}
                className={`flex items-center space-x-1.5 sm:space-x-2 px-3 sm:px-3.5 py-1.5 rounded-lg text-xs font-medium transition-all whitespace-nowrap ${
                  isActive
                    ? 'bg-[#80C7F2] text-neutral-950 font-bold shadow-xs'
                    : 'text-neutral-600 dark:text-neutral-300 hover:text-neutral-950 dark:hover:text-white hover:bg-neutral-200/60 dark:hover:bg-neutral-800/80'
                }`}
              >
                <Icon className={`w-3.5 h-3.5 ${isActive ? 'text-neutral-950' : 'text-neutral-400 dark:text-neutral-500'}`} />
                <span>{tab.label}</span>
                {tab.badge !== undefined && (
                  <span className={`px-1.5 py-0.5 text-[10px] font-bold rounded-full leading-none ${tab.badgeColor || 'bg-red-500 text-white'}`}>
                    {tab.badge}
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* 
        ========================================================================
        Mobile / Tablet Dropdown Menu Overlay: Instant Jump Navigation Drawer
        ========================================================================
      */}
      {isMobileMenuOpen && (
        <div className="lg:hidden border-t border-neutral-200 dark:border-neutral-800 bg-white/98 dark:bg-[#181818]/98 px-4 py-3 shadow-xl max-h-[75vh] overflow-y-auto animate-in fade-in slide-in-from-top-2 duration-150">
          <p className="text-[11px] font-bold uppercase tracking-wider text-neutral-400 mb-2 px-1">
            Headquarters Navigation Menu
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-1.5">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  id={`mobile-nav-${tab.id}`}
                  onClick={() => handleTabClick(tab.id)}
                  className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-semibold transition-all ${
                    isActive
                      ? 'bg-[#80C7F2] text-neutral-950 font-bold shadow-xs'
                      : 'bg-neutral-50 dark:bg-neutral-900 text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800'
                  }`}
                >
                  <div className="flex items-center space-x-2.5 truncate">
                    <Icon className={`w-4 h-4 ${isActive ? 'text-neutral-950' : 'text-neutral-500 dark:text-neutral-400'}`} />
                    <span className="truncate">{tab.label}</span>
                  </div>
                  {tab.badge !== undefined && (
                    <span className={`px-2 py-0.5 text-[10px] font-bold rounded-full leading-none ${tab.badgeColor || 'bg-red-500 text-white'}`}>
                      {tab.badge}
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        </div>
      )}

      {/* Confirm Reset Modal */}
      {showConfirmReset && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4">
          <div className="w-full max-w-md rounded-2xl p-6 shadow-2xl border bg-white dark:bg-[#1c1c1c] border-neutral-200 dark:border-neutral-700 text-neutral-900 dark:text-white">
            <h3 className="text-lg font-bold">Reset to Default Data?</h3>
            <p className="text-sm text-neutral-500 dark:text-neutral-400 mt-2">
              This will restore all 19 branches, sample orders, inventory levels, and gourmet marshmallow catalog to default settings and re-seed Firestore.
            </p>
            <div className="flex items-center justify-end space-x-3 mt-6">
              <button
                onClick={() => setShowConfirmReset(false)}
                className="px-4 py-2 text-sm font-medium rounded-xl border border-neutral-300 dark:border-neutral-700 hover:bg-neutral-100 dark:hover:bg-neutral-800"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  resetToDefaultData();
                  setShowConfirmReset(false);
                }}
                className="px-4 py-2 text-sm font-semibold rounded-xl bg-red-600 text-white hover:bg-red-700 shadow-sm"
              >
                Reset Database
              </button>
            </div>
          </div>
        </div>
      )}

      {/* System Security & Integrity Test Suite Modal */}
      <SystemIntegrityTester
        isOpen={showTesterModal}
        onClose={() => setShowTesterModal(false)}
      />
    </header>
  );
};

