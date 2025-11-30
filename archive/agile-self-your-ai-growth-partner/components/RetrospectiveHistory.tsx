'use client';

import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Badge } from './ui/badge';
import { Progress } from './ui/progress';
import { Trash2, Search, ChevronDown, ChevronUp, Calendar, CheckCircle } from 'lucide-react';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from './ui/alert-dialog';
import { toast } from 'sonner';
import { useAuth } from '@/lib/auth/AuthContext';
import { dataService } from '@/lib/supabase/data-service';
import type { Retrospective } from '@/lib/types';

interface RetrospectiveHistoryProps {
  retrospectives: Retrospective[];
  onUpdateRetrospectives: (retrospectives: Retrospective[]) => void;
}

type FilterType = 'all' | 'weekly' | 'monthly';

// Calculate wellbeing score (same as Dashboard)
function calculateWellbeingScore(retrospective: Retrospective): number {
  const keepsCount = retrospective.keeps.length;
  const problemsCount = retrospective.problems.length;
  const triesCount = retrospective.tries.length;
  const actionsCount = retrospective.actions.length;

  const sentiment = keepsCount / Math.max(problemsCount || 1, 1);
  let score = Math.min(50 + (sentiment * 20), 90);

  if (triesCount > 0) score += 5;
  if (actionsCount > 0) score += 5;

  const totalText = [
    ...retrospective.keeps,
    ...retrospective.problems,
    ...retrospective.tries,
  ].join(' ');

  if (totalText.length > 200) score += 5;

  return Math.min(Math.round(score), 100);
}

export function RetrospectiveHistory({ retrospectives, onUpdateRetrospectives }: RetrospectiveHistoryProps) {
  const { user } = useAuth();
  const [searchQuery, setSearchQuery] = useState('');
  const [filter, setFilter] = useState<FilterType>('all');
  const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set());

  // Filter retrospectives
  const filteredRetrospectives = retrospectives.filter(retro => {
    // Filter by type
    if (filter !== 'all' && retro.type !== filter) return false;

    // Filter by search query
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      const matchesTitle = retro.title.toLowerCase().includes(query);
      const matchesKeeps = retro.keeps.some(k => k.toLowerCase().includes(query));
      const matchesProblems = retro.problems.some(p => p.toLowerCase().includes(query));
      const matchesTries = retro.tries.some(t => t.toLowerCase().includes(query));

      return matchesTitle || matchesKeeps || matchesProblems || matchesTries;
    }

    return true;
  });

  const toggleExpanded = (id: string) => {
    const newExpanded = new Set(expandedIds);
    if (newExpanded.has(id)) {
      newExpanded.delete(id);
    } else {
      newExpanded.add(id);
    }
    setExpandedIds(newExpanded);
  };

  const handleDeleteRetrospective = async (id: string) => {
    // Optimistic update
    const updated = retrospectives.filter(r => r.id !== id);

    // Sync to Supabase if authenticated
    if (user) {
      try {
        await dataService.deleteRetrospective(id);
        toast.success('Retrospective deleted');
      } catch (error) {
        console.error('Error deleting retrospective:', error);
        toast.error('Failed to delete retrospective');
        // Revert on error
        onUpdateRetrospectives(retrospectives);
        return;
      }
    } else {
      toast.success('Retrospective deleted');
    }

    onUpdateRetrospectives(updated);
  };

  const weeklyCount = retrospectives.filter(r => r.type === 'weekly').length;
  const monthlyCount = retrospectives.filter(r => r.type === 'monthly').length;

  return (
    <div className="space-y-6">
      {/* Header Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="bg-blue-50 border-blue-200">
          <CardContent className="pt-6">
            <div className="text-center">
              <p className="text-sm text-blue-700 mb-1">Total Retrospectives</p>
              <p className="text-3xl font-bold text-slate-900">{retrospectives.length}</p>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-purple-50 border-purple-200">
          <CardContent className="pt-6">
            <div className="text-center">
              <p className="text-sm text-purple-700 mb-1">Weekly Sessions</p>
              <p className="text-3xl font-bold text-slate-900">{weeklyCount}</p>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-indigo-50 border-indigo-200">
          <CardContent className="pt-6">
            <div className="text-center">
              <p className="text-sm text-indigo-700 mb-1">Monthly Sessions</p>
              <p className="text-3xl font-bold text-slate-900">{monthlyCount}</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Search and Filters */}
      <Card className="bg-white/60 backdrop-blur-sm border-slate-200">
        <CardHeader>
          <CardTitle>Retrospective History</CardTitle>
          <CardDescription>View and search your past reflections</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {/* Search Bar */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
              <Input
                type="text"
                placeholder="Search retrospectives..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10 bg-white"
              />
            </div>

            {/* Filter Buttons */}
            <div className="flex gap-2">
              <Button
                variant={filter === 'all' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setFilter('all')}
              >
                All ({retrospectives.length})
              </Button>
              <Button
                variant={filter === 'weekly' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setFilter('weekly')}
              >
                Weekly ({weeklyCount})
              </Button>
              <Button
                variant={filter === 'monthly' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setFilter('monthly')}
              >
                Monthly ({monthlyCount})
              </Button>
            </div>

            {/* Retrospectives List */}
            {filteredRetrospectives.length === 0 ? (
              <div className="text-center py-12">
                <p className="text-slate-500 mb-2">
                  {searchQuery ? 'No retrospectives match your search' : 'No retrospectives yet'}
                </p>
                <p className="text-sm text-slate-400">
                  {searchQuery ? 'Try a different search term' : 'Create your first retrospective to get started'}
                </p>
              </div>
            ) : (
              <div className="space-y-3 mt-6">
                {filteredRetrospectives.map((retro) => {
                  const score = calculateWellbeingScore(retro);
                  const isExpanded = expandedIds.has(retro.id);
                  const completedActions = retro.actions.filter(a => a.completed).length;
                  const actionCompletionRate = retro.actions.length > 0
                    ? Math.round((completedActions / retro.actions.length) * 100)
                    : 0;

                  return (
                    <div
                      key={retro.id}
                      className="rounded-lg border border-slate-300 bg-white hover:shadow-md transition-all"
                    >
                      {/* Header - Always Visible */}
                      <div className="p-4">
                        <div className="flex items-start justify-between mb-3">
                          <div className="flex-1">
                            <div className="flex items-center gap-2 mb-2">
                              <h3 className="font-semibold text-slate-900">{retro.title}</h3>
                              <Badge variant={retro.type === 'weekly' ? 'default' : 'secondary'} className="text-xs">
                                {retro.type}
                              </Badge>
                            </div>
                            <div className="flex items-center gap-2 text-sm text-slate-500">
                              <Calendar className="w-4 h-4" />
                              {new Date(retro.startDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                              {' - '}
                              {new Date(retro.endDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                            </div>
                          </div>

                          <div className="flex items-center gap-2">
                            <div className="text-right mr-2">
                              <div className="text-xs text-slate-500 mb-1">Score</div>
                              <div className={`text-lg font-bold ${score >= 70 ? 'text-green-600' : score >= 50 ? 'text-amber-600' : 'text-red-600'}`}>
                                {score}/100
                              </div>
                            </div>

                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => toggleExpanded(retro.id)}
                            >
                              {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                            </Button>

                            <AlertDialog>
                              <AlertDialogTrigger asChild>
                                <Button variant="ghost" size="icon" className="text-red-600 hover:text-red-700 hover:bg-red-50">
                                  <Trash2 className="w-4 h-4" />
                                </Button>
                              </AlertDialogTrigger>
                              <AlertDialogContent>
                                <AlertDialogHeader>
                                  <AlertDialogTitle>Delete Retrospective?</AlertDialogTitle>
                                  <AlertDialogDescription>
                                    This will permanently delete this retrospective and all its associated action items. This action cannot be undone.
                                  </AlertDialogDescription>
                                </AlertDialogHeader>
                                <AlertDialogFooter>
                                  <AlertDialogCancel>Cancel</AlertDialogCancel>
                                  <AlertDialogAction
                                    onClick={() => handleDeleteRetrospective(retro.id)}
                                    className="bg-red-600 hover:bg-red-700"
                                  >
                                    Delete
                                  </AlertDialogAction>
                                </AlertDialogFooter>
                              </AlertDialogContent>
                            </AlertDialog>
                          </div>
                        </div>

                        <div className="flex gap-4 text-sm mb-3">
                          <span className="text-green-600">{retro.keeps.length} Keeps</span>
                          <span className="text-red-600">{retro.problems.length} Problems</span>
                          <span className="text-purple-600">{retro.tries.length} Tries</span>
                          <span className="text-blue-600">{retro.actions.length} Actions</span>
                        </div>

                        <Progress value={score} className="h-2" />
                      </div>

                      {/* Expanded Details */}
                      {isExpanded && (
                        <div className="border-t border-slate-200 p-4 bg-slate-50 space-y-4">
                          {/* Keeps */}
                          {retro.keeps.length > 0 && (
                            <div>
                              <h4 className="font-semibold text-green-900 mb-2 flex items-center gap-2">
                                <CheckCircle className="w-4 h-4" />
                                Keep
                              </h4>
                              <ul className="space-y-1 ml-6">
                                {retro.keeps.map((keep, idx) => (
                                  <li key={idx} className="text-sm text-slate-700 list-disc">
                                    {keep}
                                  </li>
                                ))}
                              </ul>
                            </div>
                          )}

                          {/* Problems */}
                          {retro.problems.length > 0 && (
                            <div>
                              <h4 className="font-semibold text-red-900 mb-2">Problem</h4>
                              <ul className="space-y-1 ml-6">
                                {retro.problems.map((problem, idx) => (
                                  <li key={idx} className="text-sm text-slate-700 list-disc">
                                    {problem}
                                  </li>
                                ))}
                              </ul>
                            </div>
                          )}

                          {/* Tries */}
                          {retro.tries.length > 0 && (
                            <div>
                              <h4 className="font-semibold text-purple-900 mb-2">Try</h4>
                              <ul className="space-y-1 ml-6">
                                {retro.tries.map((tryItem, idx) => (
                                  <li key={idx} className="text-sm text-slate-700 list-disc">
                                    {tryItem}
                                  </li>
                                ))}
                              </ul>
                            </div>
                          )}

                          {/* Actions */}
                          {retro.actions.length > 0 && (
                            <div>
                              <h4 className="font-semibold text-blue-900 mb-2 flex items-center justify-between">
                                <span>Actions</span>
                                <span className="text-xs font-normal text-slate-600">
                                  {completedActions}/{retro.actions.length} completed ({actionCompletionRate}%)
                                </span>
                              </h4>
                              <ul className="space-y-2 ml-6">
                                {retro.actions.map((action) => (
                                  <li key={action.id} className="text-sm flex items-start gap-2">
                                    <CheckCircle
                                      className={`w-4 h-4 mt-0.5 ${
                                        action.completed ? 'text-green-600' : 'text-slate-300'
                                      }`}
                                    />
                                    <span className={action.completed ? 'line-through text-slate-500' : 'text-slate-700'}>
                                      {action.text}
                                    </span>
                                  </li>
                                ))}
                              </ul>
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
