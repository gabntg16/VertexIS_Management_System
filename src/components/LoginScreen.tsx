import React, { useState } from 'react';
import { useData } from '../context/DataContext';
import { ShieldCheck, Store, Lock, Mail, ArrowRight, Sparkles, AlertCircle } from 'lucide-react';

export const LoginScreen: React.FC = () => {
  const { login, themeMode } = useData();
  const [email, setEmail] = useState('admin@marshbites.com');
  const [password, setPassword] = useState('admin123');
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    const user = login(email, password);
    if (!user) {
      setError('Invalid email or password. Use demo buttons below or check credentials.');
    }
  };

  const handleQuickLogin = (quickEmail: string, quickPass: string) => {
    setEmail(quickEmail);
    setPassword(quickPass);
    setError(null);
    login(quickEmail, quickPass);
  };

  return (
    <div className={`min-h-screen flex items-center justify-center px-4 sm:px-6 lg:px-8 transition-colors ${
      themeMode === 'dark' ? 'bg-[#0e0e0e] text-white' : 'bg-[#F8F9FA] text-[#231F20]'
    }`}>
      <div className="w-full max-w-md space-y-6">
        {/* Brand Card */}
        <div className={`rounded-3xl p-8 shadow-xl border text-center relative overflow-hidden transition-all ${
          themeMode === 'dark'
            ? 'bg-[#161616] border-neutral-800'
            : 'bg-white border-[#80C7F2]/25'
        }`}>
          {/* Subtle brand gradient background pill */}
          <div className="absolute -top-12 -right-12 w-36 h-36 rounded-full bg-[#80C7F2]/20 blur-2xl pointer-events-none" />
          <div className="absolute -bottom-12 -left-12 w-36 h-36 rounded-full bg-[#F37021]/15 blur-2xl pointer-events-none" />

          {/* Logo */}
          <div className="mx-auto w-24 h-24 rounded-3xl bg-white dark:bg-neutral-800 p-1.5 shadow-lg mb-4 flex items-center justify-center border border-neutral-200/90 dark:border-neutral-700 overflow-hidden">
            <img
              src="/marshbites_logo.jpg"
              alt="The Marsh Bites"
              className="w-full h-full object-cover rounded-2xl"
              referrerPolicy="no-referrer"
              onError={(e) => {
                const target = e.currentTarget;
                if (target.src.indexOf('marshbites_withText.png') === -1) {
                  target.src = '/marshbites_withText.png';
                }
              }}
            />
          </div>

          <h1 className="text-2xl font-black tracking-tight">
            Vertex<span className="text-[#F37021]">IS</span>
          </h1>
          <p className="text-sm font-semibold text-neutral-600 dark:text-neutral-300 mt-0.5">
            The Marsh Bites • Gourmet Marshmallows
          </p>
          <div className="mt-2 inline-flex items-center space-x-1.5 px-3 py-1 rounded-full bg-[#80C7F2]/10 text-xs font-semibold text-[#1a7bb5] dark:text-[#80C7F2] border border-[#80C7F2]/20">
            <Sparkles className="w-3.5 h-3.5 text-[#F37021]" />
            <span>Handmade Gourmet Marshmallows from Bicol</span>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="mt-6 space-y-4 text-left">
            {error && (
              <div className="flex items-center space-x-2 p-3 rounded-xl bg-red-500/10 border border-red-500/30 text-red-600 dark:text-red-400 text-xs">
                <AlertCircle className="w-4 h-4 flex-shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-neutral-500 mb-1">
                Email Address
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-neutral-400">
                  <Mail className="w-4 h-4" />
                </div>
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@marshbites.com"
                  className={`w-full pl-10 pr-4 py-3 rounded-xl text-sm border focus:outline-none focus:ring-2 focus:ring-[#80C7F2] transition-colors ${
                    themeMode === 'dark'
                      ? 'bg-neutral-900/80 border-neutral-700 text-white placeholder-neutral-500'
                      : 'bg-neutral-50 border-neutral-200 text-neutral-900 placeholder-neutral-400'
                  }`}
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-neutral-500 mb-1">
                Password
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-neutral-400">
                  <Lock className="w-4 h-4" />
                </div>
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className={`w-full pl-10 pr-4 py-3 rounded-xl text-sm border focus:outline-none focus:ring-2 focus:ring-[#80C7F2] transition-colors ${
                    themeMode === 'dark'
                      ? 'bg-neutral-900/80 border-neutral-700 text-white placeholder-neutral-500'
                      : 'bg-neutral-50 border-neutral-200 text-neutral-900 placeholder-neutral-400'
                  }`}
                />
              </div>
            </div>

            <button
              type="submit"
              className="w-full mt-2 py-3.5 px-4 rounded-xl bg-gradient-to-r from-[#F37021] to-amber-500 text-white font-bold text-sm shadow-md hover:opacity-95 active:scale-[0.99] transition-all flex items-center justify-center space-x-2"
            >
              <span>Sign In to System</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </form>

          {/* Quick Demo Access Bar */}
          <div className="mt-8 pt-6 border-t border-neutral-200 dark:border-neutral-800">
            <p className="text-xs font-bold uppercase tracking-wider text-neutral-400 mb-3 text-center">
              Instant Demo Logins
            </p>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => handleQuickLogin('admin@marshbites.com', 'admin123')}
                className={`flex items-center space-x-2 p-2.5 rounded-xl border text-xs font-semibold text-left transition-all ${
                  themeMode === 'dark'
                    ? 'bg-neutral-800/80 border-amber-500/30 text-amber-400 hover:bg-amber-500/20'
                    : 'bg-amber-50 border-amber-200 text-amber-800 hover:bg-amber-100'
                }`}
              >
                <ShieldCheck className="w-4 h-4 text-amber-500 flex-shrink-0" />
                <div className="truncate">
                  <div className="font-bold">Super Admin</div>
                  <div className="text-[10px] opacity-75">All Branches</div>
                </div>
              </button>

              <button
                type="button"
                onClick={() => handleQuickLogin('legazpi@marshbites.com', 'branch123')}
                className={`flex items-center space-x-2 p-2.5 rounded-xl border text-xs font-semibold text-left transition-all ${
                  themeMode === 'dark'
                    ? 'bg-neutral-800/80 border-[#80C7F2]/30 text-[#80C7F2] hover:bg-[#80C7F2]/20'
                    : 'bg-sky-50 border-sky-200 text-sky-800 hover:bg-sky-100'
                }`}
              >
                <Store className="w-4 h-4 text-[#80C7F2] flex-shrink-0" />
                <div className="truncate">
                  <div className="font-bold">Legazpi Branch</div>
                  <div className="text-[10px] opacity-75">Bicol Base</div>
                </div>
              </button>

              <button
                type="button"
                onClick={() => handleQuickLogin('cabuyao@marshbites.com', 'branch123')}
                className={`flex items-center space-x-2 p-2.5 rounded-xl border text-xs font-semibold text-left transition-all ${
                  themeMode === 'dark'
                    ? 'bg-neutral-800/80 border-[#80C7F2]/30 text-[#80C7F2] hover:bg-[#80C7F2]/20'
                    : 'bg-sky-50 border-sky-200 text-sky-800 hover:bg-sky-100'
                }`}
              >
                <Store className="w-4 h-4 text-[#80C7F2] flex-shrink-0" />
                <div className="truncate">
                  <div className="font-bold">Cabuyao Branch</div>
                  <div className="text-[10px] opacity-75">Laguna</div>
                </div>
              </button>

              <button
                type="button"
                onClick={() => handleQuickLogin('makati@marshbites.com', 'branch123')}
                className={`flex items-center space-x-2 p-2.5 rounded-xl border text-xs font-semibold text-left transition-all ${
                  themeMode === 'dark'
                    ? 'bg-neutral-800/80 border-[#80C7F2]/30 text-[#80C7F2] hover:bg-[#80C7F2]/20'
                    : 'bg-sky-50 border-sky-200 text-sky-800 hover:bg-sky-100'
                }`}
              >
                <Store className="w-4 h-4 text-[#80C7F2] flex-shrink-0" />
                <div className="truncate">
                  <div className="font-bold">Makati Branch</div>
                  <div className="text-[10px] opacity-75">Metro Manila</div>
                </div>
              </button>
            </div>
          </div>
        </div>

        {/* Footer Note */}
        <p className="text-center text-xs text-neutral-400">
          VertexIS Branch Management System • Handcrafted in Bicol
        </p>
      </div>
    </div>
  );
};
