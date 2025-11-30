'use client';

import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Checkbox } from './ui/checkbox';
import { Badge } from './ui/badge';
import { Trash2, Calendar, ExternalLink } from 'lucide-react';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from './ui/alert-dialog';
import { toast } from 'sonner';
import { useAuth } from '@/lib/auth/AuthContext';
import { dataService } from '@/lib/supabase/data-service';
import type { Retrospective, Action } from '@/lib/types';

interface ActionsListProps {
  retrospectives: Retrospective[];
  onUpdateRetrospectives: (retrospectives: Retrospective[]) => void;
}

type FilterType = 'all' | 'pending' | 'completed';

export function ActionsList({ retrospectives, onUpdateRetrospectives }: ActionsListProps) {
  const { user } = useAuth();
  const [filter, setFilter] = useState<FilterType>('all');

  // Flatten all actions from all retrospectives
  const allActions = retrospectives.flatMap(retro =>
    retro.actions.map(action => ({
      ...action,
      retroTitle: retro.title,
      retroDate: retro.date,
    }))
  );

  // Filter actions based on selected filter
  const filteredActions = allActions.filter(action => {
    if (filter === 'pending') return !action.completed;
    if (filter === 'completed') return action.completed;
    return true;
  });

  const handleToggleComplete = async (actionId: string) => {
    const action = allActions.find(a => a.id === actionId);
    if (!action) return;

    // Optimistic update
    const updated = retrospectives.map(retro => ({
      ...retro,
      actions: retro.actions.map(a =>
        a.id === actionId
          ? { ...a, completed: !a.completed }
          : a
      ),
    }));
    setFilter(filter); // Trigger re-render

    // Sync to Supabase if authenticated
    if (user) {
      try {
        await dataService.updateAction(actionId, { completed: !action.completed });
        toast.success(action.completed ? 'Action marked as pending' : 'Action completed! 🎉');
      } catch (error) {
        console.error('Error updating action:', error);
        toast.error('Failed to update action');
        // Revert on error
        onUpdateRetrospectives(retrospectives);
        return;
      }
    }

    onUpdateRetrospectives(updated);
  };

  const handleDeleteAction = async (actionId: string) => {
    // Optimistic update
    const updated = retrospectives.map(retro => ({
      ...retro,
      actions: retro.actions.filter(action => action.id !== actionId),
    }));

    // Sync to Supabase if authenticated
    if (user) {
      try {
        await dataService.deleteAction(actionId);
        toast.success('Action deleted');
      } catch (error) {
        console.error('Error deleting action:', error);
        toast.error('Failed to delete action');
        // Revert on error
        onUpdateRetrospectives(retrospectives);
        return;
      }
    } else {
      toast.success('Action deleted');
    }

    onUpdateRetrospectives(updated);
  };

  const pendingCount = allActions.filter(a => !a.completed).length;
  const completedCount = allActions.filter(a => a.completed).length;
  const completionRate = allActions.length > 0
    ? Math.round((completedCount / allActions.length) * 100)
    : 0;

  return (
    <div className="space-y-6">
      {/* Header Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="bg-blue-50 border-blue-200">
          <CardContent className="pt-6">
            <div className="text-center">
              <p className="text-sm text-blue-700 mb-1">Total Actions</p>
              <p className="text-3xl font-bold text-slate-900">{allActions.length}</p>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-amber-50 border-amber-200">
          <CardContent className="pt-6">
            <div className="text-center">
              <p className="text-sm text-amber-700 mb-1">Pending</p>
              <p className="text-3xl font-bold text-slate-900">{pendingCount}</p>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-green-50 border-green-200">
          <CardContent className="pt-6">
            <div className="text-center">
              <p className="text-sm text-green-700 mb-1">Completion Rate</p>
              <p className="text-3xl font-bold text-slate-900">{completionRate}%</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <Card className="bg-white/60 backdrop-blur-sm border-slate-200">
        <CardHeader>
          <CardTitle>Action Items</CardTitle>
          <CardDescription>Track and manage all your action items</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex gap-2 mb-6">
            <Button
              variant={filter === 'all' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setFilter('all')}
            >
              All ({allActions.length})
            </Button>
            <Button
              variant={filter === 'pending' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setFilter('pending')}
            >
              Pending ({pendingCount})
            </Button>
            <Button
              variant={filter === 'completed' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setFilter('completed')}
            >
              Completed ({completedCount})
            </Button>
          </div>

          {/* Actions List */}
          {filteredActions.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-slate-500 mb-2">No {filter === 'all' ? '' : filter} actions yet</p>
              <p className="text-sm text-slate-400">
                {filter === 'pending' && allActions.length > 0
                  ? 'Great job! All actions are completed 🎉'
                  : 'Create a retrospective with action items to get started'}
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {filteredActions.map((action) => (
                <div
                  key={action.id}
                  className={`flex items-start gap-3 p-4 rounded-lg border transition-all ${
                    action.completed
                      ? 'bg-slate-50 border-slate-200 opacity-60'
                      : 'bg-white border-slate-300 hover:border-blue-300 hover:shadow-sm'
                  }`}
                >
                  <Checkbox
                    id={action.id}
                    checked={action.completed}
                    onCheckedChange={() => handleToggleComplete(action.id)}
                    className="mt-1"
                  />

                  <div className="flex-1">
                    <label
                      htmlFor={action.id}
                      className={`cursor-pointer block text-slate-900 ${
                        action.completed ? 'line-through' : ''
                      }`}
                    >
                      {action.text}
                    </label>

                    <div className="flex flex-wrap items-center gap-2 mt-2">
                      <Badge variant="secondary" className="text-xs">
                        <ExternalLink className="w-3 h-3 mr-1" />
                        {action.retroTitle}
                      </Badge>

                      {action.deadline && (
                        <Badge
                          variant={
                            new Date(action.deadline) < new Date() && !action.completed
                              ? 'destructive'
                              : 'outline'
                          }
                          className="text-xs"
                        >
                          <Calendar className="w-3 h-3 mr-1" />
                          {new Date(action.deadline).toLocaleDateString('en-US', {
                            month: 'short',
                            day: 'numeric',
                          })}
                        </Badge>
                      )}

                      {action.fromTryItem && (
                        <Badge variant="outline" className="text-xs text-purple-600 border-purple-300">
                          From Try
                        </Badge>
                      )}
                    </div>
                  </div>

                  <AlertDialog>
                    <AlertDialogTrigger asChild>
                      <Button variant="ghost" size="icon" className="text-red-600 hover:text-red-700 hover:bg-red-50">
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </AlertDialogTrigger>
                    <AlertDialogContent>
                      <AlertDialogHeader>
                        <AlertDialogTitle>Delete Action Item?</AlertDialogTitle>
                        <AlertDialogDescription>
                          This will permanently delete this action item. This action cannot be undone.
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel>Cancel</AlertDialogCancel>
                        <AlertDialogAction
                          onClick={() => handleDeleteAction(action.id)}
                          className="bg-red-600 hover:bg-red-700"
                        >
                          Delete
                        </AlertDialogAction>
                      </AlertDialogFooter>
                    </AlertDialogContent>
                  </AlertDialog>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
