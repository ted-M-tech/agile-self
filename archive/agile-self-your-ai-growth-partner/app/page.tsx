'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { LandingPage } from '@/components/LandingPage';
import { Dashboard } from '@/components/Dashboard';
import { KPTAEntry } from '@/components/KPTAEntry';
import { ActionsList } from '@/components/ActionsList';
import { RetrospectiveHistory } from '@/components/RetrospectiveHistory';
import { Settings as SettingsComponent } from '@/components/Settings';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Home, Plus, ListTodo, History, Settings, LogOut } from 'lucide-react';
import { Toaster, toast } from 'sonner';
import { useAuth } from '@/lib/auth/AuthContext';
import { dataService } from '@/lib/supabase/data-service';
import type { Retrospective } from '@/lib/types';

type TabType = 'home' | 'new' | 'actions' | 'history' | 'settings';

export default function HomePage() {
  const { user, loading: authLoading, signOut } = useAuth();
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(true);
  const [showApp, setShowApp] = useState(false);
  const [activeTab, setActiveTab] = useState<TabType>('home');
  const [retrospectives, setRetrospectives] = useState<Retrospective[]>([]);

  // Load data based on authentication status
  useEffect(() => {
    async function loadData() {
      if (authLoading) return;

      // If user is authenticated, load from Supabase
      if (user) {
        try {
          const data = await dataService.fetchRetrospectives(user.id);
          setRetrospectives(data);
          setShowApp(true);
        } catch (error) {
          console.error('Error loading retrospectives:', error);
          toast.error('Failed to load retrospectives');
        }
        setIsLoading(false);
        return;
      }

      // If not authenticated, check localStorage for local-only mode
      const hasStarted = localStorage.getItem('hasStarted');
      const stored = localStorage.getItem('retrospectives');

      if (hasStarted === 'true') {
        setShowApp(true);
      }

      if (stored) {
        try {
          setRetrospectives(JSON.parse(stored));
        } catch (e) {
          console.error('Error parsing stored retrospectives:', e);
        }
      }

      setIsLoading(false);
    }

    loadData();
  }, [user, authLoading]);

  const handleGetStarted = () => {
    // If not authenticated, ask user to sign in or continue offline
    if (!user) {
      router.push('/login');
      return;
    }
    localStorage.setItem('hasStarted', 'true');
    setShowApp(true);
  };

  const handleNewRetrospective = () => {
    setActiveTab('new');
  };

  const handleSaveRetrospective = async (newRetro: Retrospective) => {
    const updated = [newRetro, ...retrospectives];
    setRetrospectives(updated);

    // Sync to Supabase if authenticated
    if (user) {
      try {
        await dataService.saveRetrospective(user.id, newRetro);
        toast.success('Retrospective saved!');
      } catch (error) {
        console.error('Error saving retrospective:', error);
        toast.error('Failed to save retrospective');
      }
    } else {
      // Save to localStorage for offline mode
      localStorage.setItem('retrospectives', JSON.stringify(updated));
    }

    setActiveTab('home');
  };

  const handleCancelEntry = () => {
    setActiveTab('home');
  };

  const handleUpdateRetrospectives = async (updated: Retrospective[]) => {
    setRetrospectives(updated);

    // Sync to Supabase if authenticated
    if (user) {
      // This is called when actions are updated or retrospectives deleted
      // We need to reload from Supabase to ensure consistency
      try {
        const fresh = await dataService.fetchRetrospectives(user.id);
        setRetrospectives(fresh);
      } catch (error) {
        console.error('Error reloading retrospectives:', error);
        toast.error('Failed to sync changes');
      }
    } else {
      localStorage.setItem('retrospectives', JSON.stringify(updated));
    }
  };

  const handleSignOut = async () => {
    try {
      await signOut();
      setRetrospectives([]);
      setShowApp(false);
      localStorage.removeItem('hasStarted');
      localStorage.removeItem('retrospectives');
      router.push('/');
      toast.success('Signed out successfully');
    } catch (error) {
      console.error('Error signing out:', error);
      toast.error('Failed to sign out');
    }
  };

  if (isLoading) {
    return null;
  }

  if (!showApp) {
    return <LandingPage onGetStarted={handleGetStarted} />;
  }

  const pendingActions = retrospectives
    .flatMap(r => r.actions)
    .filter(a => !a.completed).length;

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-slate-50">
      <Toaster />
      <header className="bg-white/80 backdrop-blur-md border-b border-slate-200 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <h1 className="text-xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              Agile Self
            </h1>
            <div className="flex items-center gap-4">
              <p className="text-sm text-slate-600 hidden sm:block">
                Turn Reflection Into Action
              </p>
              {user && (
                <div className="flex items-center gap-3">
                  <div className="hidden md:flex items-center gap-2">
                    {user.user_metadata?.avatar_url && (
                      <img
                        src={user.user_metadata.avatar_url}
                        alt="User avatar"
                        className="w-8 h-8 rounded-full"
                      />
                    )}
                    <span className="text-sm text-slate-700">
                      {user.user_metadata?.full_name || user.email}
                    </span>
                  </div>
                  <Button
                    onClick={handleSignOut}
                    variant="ghost"
                    size="sm"
                    className="gap-2"
                  >
                    <LogOut className="w-4 h-4" />
                    <span className="hidden sm:inline">Sign Out</span>
                  </Button>
                </div>
              )}
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Navigation */}
        <div className="mb-6">
          <div className="inline-flex gap-2 p-1 bg-white/80 backdrop-blur-sm border border-slate-200 rounded-lg">
            <Button
              variant={activeTab === 'home' ? 'default' : 'ghost'}
              size="sm"
              onClick={() => setActiveTab('home')}
              className="gap-2"
            >
              <Home className="w-4 h-4" />
              <span className="hidden sm:inline">Home</span>
            </Button>
            <Button
              variant={activeTab === 'new' ? 'default' : 'ghost'}
              size="sm"
              onClick={() => setActiveTab('new')}
              className="gap-2"
            >
              <Plus className="w-4 h-4" />
              <span className="hidden sm:inline">New</span>
            </Button>
            <Button
              variant={activeTab === 'actions' ? 'default' : 'ghost'}
              size="sm"
              onClick={() => setActiveTab('actions')}
              className="gap-2 relative"
            >
              <ListTodo className="w-4 h-4" />
              <span className="hidden sm:inline">Actions</span>
              {pendingActions > 0 && (
                <Badge className="ml-1 h-5 min-w-5 px-1 text-xs bg-blue-600">
                  {pendingActions}
                </Badge>
              )}
            </Button>
            <Button
              variant={activeTab === 'history' ? 'default' : 'ghost'}
              size="sm"
              onClick={() => setActiveTab('history')}
              className="gap-2"
            >
              <History className="w-4 h-4" />
              <span className="hidden sm:inline">History</span>
            </Button>
            <Button
              variant={activeTab === 'settings' ? 'default' : 'ghost'}
              size="sm"
              onClick={() => setActiveTab('settings')}
              className="gap-2"
            >
              <Settings className="w-4 h-4" />
              <span className="hidden sm:inline">Settings</span>
            </Button>
          </div>
        </div>

        {/* Content */}
        <div>
          {activeTab === 'home' && (
            <Dashboard
              retrospectives={retrospectives}
              onNewRetrospective={handleNewRetrospective}
            />
          )}

          {activeTab === 'new' && (
            <KPTAEntry
              onSave={handleSaveRetrospective}
              onCancel={handleCancelEntry}
            />
          )}

          {activeTab === 'actions' && (
            <ActionsList
              retrospectives={retrospectives}
              onUpdateRetrospectives={handleUpdateRetrospectives}
            />
          )}

          {activeTab === 'history' && (
            <RetrospectiveHistory
              retrospectives={retrospectives}
              onUpdateRetrospectives={handleUpdateRetrospectives}
            />
          )}

          {activeTab === 'settings' && (
            <SettingsComponent
              retrospectives={retrospectives}
              onUpdateRetrospectives={handleUpdateRetrospectives}
            />
          )}
        </div>
      </main>
    </div>
  );
}
