'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Label } from './ui/label';
import { Switch } from './ui/switch';
import { RadioGroup, RadioGroupItem } from './ui/radio-group';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from './ui/alert-dialog';
import { Bell, Download, Trash2, Info, Moon, Sun } from 'lucide-react';
import { toast } from 'sonner';
import type { Retrospective } from '@/lib/types';

interface SettingsProps {
  retrospectives: Retrospective[];
  onUpdateRetrospectives: (retrospectives: Retrospective[]) => void;
}

interface ReminderSettings {
  enabled: boolean;
  frequency: 'weekly' | 'monthly';
  dayOfWeek?: number; // 0-6 for Sunday-Saturday
  dayOfMonth?: number; // 1-31
}

const DAYS_OF_WEEK = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

export function Settings({ retrospectives, onUpdateRetrospectives }: SettingsProps) {
  const [reminderSettings, setReminderSettings] = useState<ReminderSettings>({
    enabled: false,
    frequency: 'weekly',
    dayOfWeek: 0,
    dayOfMonth: 1,
  });
  const [theme, setTheme] = useState<'light' | 'dark'>('light');

  // Load settings from localStorage on mount
  useEffect(() => {
    const storedReminders = localStorage.getItem('reminderSettings');
    if (storedReminders) {
      try {
        setReminderSettings(JSON.parse(storedReminders));
      } catch (e) {
        console.error('Error parsing reminder settings:', e);
      }
    }

    const storedTheme = localStorage.getItem('theme') as 'light' | 'dark' | null;
    if (storedTheme) {
      setTheme(storedTheme);
    }
  }, []);

  const updateReminderSettings = (updates: Partial<ReminderSettings>) => {
    const newSettings = { ...reminderSettings, ...updates };
    setReminderSettings(newSettings);
    localStorage.setItem('reminderSettings', JSON.stringify(newSettings));
    toast.success('Reminder settings updated');
  };

  const handleExportData = () => {
    const data = {
      retrospectives,
      settings: {
        reminders: reminderSettings,
        theme,
      },
      exportedAt: new Date().toISOString(),
      version: '2.0',
    };

    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `agile-self-export-${new Date().toISOString().split('T')[0]}.json`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast.success('Data exported successfully');
  };

  const handleClearAllData = () => {
    onUpdateRetrospectives([]);
    localStorage.removeItem('retrospectives');
    localStorage.removeItem('reminderSettings');
    localStorage.removeItem('theme');
    toast.success('All data cleared');
  };

  const handleThemeChange = (newTheme: 'light' | 'dark') => {
    setTheme(newTheme);
    localStorage.setItem('theme', newTheme);
    toast.success(`Theme changed to ${newTheme} mode`);
    // Note: Actual dark mode implementation would require updating the root HTML class
  };

  const totalActions = retrospectives.flatMap(r => r.actions).length;
  const completedActions = retrospectives.flatMap(r => r.actions).filter(a => a.completed).length;

  return (
    <div className="space-y-6">
      {/* Reminder Settings */}
      <Card className="bg-white/60 backdrop-blur-sm border-slate-200">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Bell className="w-5 h-5 text-blue-600" />
            Reminder Settings
          </CardTitle>
          <CardDescription>Configure when you want to be reminded to reflect</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Enable/Disable Reminders */}
          <div className="flex items-center justify-between">
            <div>
              <Label htmlFor="reminders-enabled" className="text-base font-medium">
                Enable Reminders
              </Label>
              <p className="text-sm text-slate-500 mt-1">
                Get notifications to complete your retrospectives
              </p>
            </div>
            <Switch
              id="reminders-enabled"
              checked={reminderSettings.enabled}
              onCheckedChange={(checked) => updateReminderSettings({ enabled: checked })}
            />
          </div>

          {reminderSettings.enabled && (
            <>
              {/* Frequency Selection */}
              <div>
                <Label className="mb-3 block">Reminder Frequency</Label>
                <RadioGroup
                  value={reminderSettings.frequency}
                  onValueChange={(value) => updateReminderSettings({ frequency: value as 'weekly' | 'monthly' })}
                >
                  <div className="space-y-3">
                    <label
                      htmlFor="weekly"
                      className={`flex items-center space-x-3 p-4 rounded-lg border-2 cursor-pointer transition-all ${
                        reminderSettings.frequency === 'weekly'
                          ? 'border-blue-500 bg-blue-50'
                          : 'border-slate-200 bg-white hover:border-blue-300'
                      }`}
                    >
                      <RadioGroupItem value="weekly" id="weekly" />
                      <div>
                        <div className="text-slate-900 font-medium">Weekly</div>
                        <div className="text-slate-500 text-sm">Reflect on your week every 7 days</div>
                      </div>
                    </label>
                    <label
                      htmlFor="monthly"
                      className={`flex items-center space-x-3 p-4 rounded-lg border-2 cursor-pointer transition-all ${
                        reminderSettings.frequency === 'monthly'
                          ? 'border-blue-500 bg-blue-50'
                          : 'border-slate-200 bg-white hover:border-blue-300'
                      }`}
                    >
                      <RadioGroupItem value="monthly" id="monthly" />
                      <div>
                        <div className="text-slate-900 font-medium">Monthly</div>
                        <div className="text-slate-500 text-sm">Reflect on your month once per month</div>
                      </div>
                    </label>
                  </div>
                </RadioGroup>
              </div>

              {/* Day Selection */}
              {reminderSettings.frequency === 'weekly' && (
                <div>
                  <Label className="mb-3 block">Reminder Day</Label>
                  <RadioGroup
                    value={reminderSettings.dayOfWeek?.toString() || '0'}
                    onValueChange={(value) => updateReminderSettings({ dayOfWeek: parseInt(value) })}
                  >
                    <div className="grid grid-cols-2 gap-2">
                      {DAYS_OF_WEEK.map((day, index) => (
                        <label
                          key={index}
                          htmlFor={`day-${index}`}
                          className={`flex items-center space-x-2 p-3 rounded-lg border cursor-pointer transition-all ${
                            reminderSettings.dayOfWeek === index
                              ? 'border-blue-500 bg-blue-50'
                              : 'border-slate-200 bg-white hover:border-blue-300'
                          }`}
                        >
                          <RadioGroupItem value={index.toString()} id={`day-${index}`} />
                          <span className="text-sm">{day}</span>
                        </label>
                      ))}
                    </div>
                  </RadioGroup>
                </div>
              )}

              {reminderSettings.frequency === 'monthly' && (
                <div>
                  <Label htmlFor="day-of-month" className="mb-3 block">
                    Reminder Day of Month
                  </Label>
                  <select
                    id="day-of-month"
                    value={reminderSettings.dayOfMonth || 1}
                    onChange={(e) => updateReminderSettings({ dayOfMonth: parseInt(e.target.value) })}
                    className="w-full p-2 border border-slate-300 rounded-lg bg-white"
                  >
                    {Array.from({ length: 31 }, (_, i) => i + 1).map(day => (
                      <option key={day} value={day}>
                        Day {day}
                      </option>
                    ))}
                  </select>
                  <p className="text-xs text-slate-500 mt-2">
                    Note: For months with fewer than {reminderSettings.dayOfMonth} days, the reminder will be sent on the last day of the month.
                  </p>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      {/* Appearance */}
      <Card className="bg-white/60 backdrop-blur-sm border-slate-200">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            {theme === 'light' ? <Sun className="w-5 h-5 text-amber-600" /> : <Moon className="w-5 h-5 text-indigo-600" />}
            Appearance
          </CardTitle>
          <CardDescription>Customize how Agile Self looks</CardDescription>
        </CardHeader>
        <CardContent>
          <div>
            <Label className="mb-3 block">Theme</Label>
            <RadioGroup value={theme} onValueChange={(value) => handleThemeChange(value as 'light' | 'dark')}>
              <div className="grid grid-cols-2 gap-3">
                <label
                  htmlFor="light-theme"
                  className={`flex items-center space-x-3 p-4 rounded-lg border-2 cursor-pointer transition-all ${
                    theme === 'light'
                      ? 'border-amber-500 bg-amber-50'
                      : 'border-slate-200 bg-white hover:border-amber-300'
                  }`}
                >
                  <RadioGroupItem value="light" id="light-theme" />
                  <div className="flex items-center gap-2">
                    <Sun className="w-4 h-4" />
                    <span>Light</span>
                  </div>
                </label>
                <label
                  htmlFor="dark-theme"
                  className={`flex items-center space-x-3 p-4 rounded-lg border-2 cursor-pointer transition-all ${
                    theme === 'dark'
                      ? 'border-indigo-500 bg-indigo-50'
                      : 'border-slate-200 bg-white hover:border-indigo-300'
                  }`}
                >
                  <RadioGroupItem value="dark" id="dark-theme" />
                  <div className="flex items-center gap-2">
                    <Moon className="w-4 h-4" />
                    <span>Dark</span>
                  </div>
                </label>
              </div>
            </RadioGroup>
            <p className="text-xs text-slate-500 mt-2">
              Dark mode UI coming soon
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Data Management */}
      <Card className="bg-white/60 backdrop-blur-sm border-slate-200">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Download className="w-5 h-5 text-green-600" />
            Data Management
          </CardTitle>
          <CardDescription>Export or clear your retrospective data</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Export Data */}
          <div className="flex items-center justify-between p-4 bg-green-50 rounded-lg border border-green-200">
            <div>
              <p className="font-medium text-slate-900">Export All Data</p>
              <p className="text-sm text-slate-600 mt-1">
                Download all your retrospectives and settings as JSON
              </p>
            </div>
            <Button onClick={handleExportData} variant="outline" className="border-green-600 text-green-700 hover:bg-green-100">
              <Download className="w-4 h-4 mr-2" />
              Export
            </Button>
          </div>

          {/* Clear All Data */}
          <div className="flex items-center justify-between p-4 bg-red-50 rounded-lg border border-red-200">
            <div>
              <p className="font-medium text-slate-900">Clear All Data</p>
              <p className="text-sm text-slate-600 mt-1">
                Permanently delete all retrospectives and settings
              </p>
            </div>
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button variant="outline" className="border-red-600 text-red-700 hover:bg-red-100">
                  <Trash2 className="w-4 h-4 mr-2" />
                  Clear
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>Clear All Data?</AlertDialogTitle>
                  <AlertDialogDescription>
                    This will permanently delete all {retrospectives.length} retrospective{retrospectives.length !== 1 ? 's' : ''}, {totalActions} action item{totalActions !== 1 ? 's' : ''}, and all settings. This action cannot be undone.
                    <br /><br />
                    Consider exporting your data first.
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>Cancel</AlertDialogCancel>
                  <AlertDialogAction
                    onClick={handleClearAllData}
                    className="bg-red-600 hover:bg-red-700"
                  >
                    Delete Everything
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          </div>
        </CardContent>
      </Card>

      {/* About */}
      <Card className="bg-white/60 backdrop-blur-sm border-slate-200">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Info className="w-5 h-5 text-blue-600" />
            About Agile Self
          </CardTitle>
          <CardDescription>Your AI Growth Partner</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-slate-600">Version</span>
              <span className="font-medium text-slate-900">2.0.0 MVP</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-600">Framework</span>
              <span className="font-medium text-slate-900">Next.js 14</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-600">Total Retrospectives</span>
              <span className="font-medium text-slate-900">{retrospectives.length}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-600">Actions Completed</span>
              <span className="font-medium text-slate-900">{completedActions} / {totalActions}</span>
            </div>
          </div>

          <div className="pt-4 border-t border-slate-200">
            <p className="text-sm text-slate-600 mb-2">
              <strong className="text-slate-900">Agile Self</strong> helps you turn reflection into action using the KPTA framework.
            </p>
            <p className="text-xs text-slate-500">
              Built with Next.js, TypeScript, Tailwind CSS, and shadcn/ui
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
