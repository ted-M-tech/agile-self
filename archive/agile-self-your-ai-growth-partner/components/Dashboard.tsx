'use client';

import { useState, useEffect, useRef } from 'react';
import { Brain, TrendingUp, Lightbulb, AlertCircle, Sparkles, Plus, Calendar, Loader2 } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';
import { Button } from './ui/button';
import { Progress } from './ui/progress';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { motion } from 'framer-motion';
import { toast } from 'sonner';
import type { Retrospective } from '@/lib/types';

interface DashboardProps {
  retrospectives: Retrospective[];
  onNewRetrospective: () => void;
}

interface WellbeingData {
  date: string;
  score: number;
  label: string;
}

interface AIInsight {
  type: 'pattern' | 'suggestion' | 'achievement' | 'warning';
  title: string;
  description: string;
  category?: 'strength' | 'growth';
}

// Calculate wellbeing score based on sentiment analysis
function calculateWellbeingScore(retrospective: Retrospective): number {
  const keepsCount = retrospective.keeps.length;
  const problemsCount = retrospective.problems.length;
  const triesCount = retrospective.tries.length;
  const actionsCount = retrospective.actions.length;

  // Base score from keeps vs problems ratio
  const sentiment = keepsCount / Math.max(problemsCount || 1, 1);
  let score = Math.min(50 + (sentiment * 20), 90);

  // Boost for taking action
  if (triesCount > 0) score += 5;
  if (actionsCount > 0) score += 5;

  // Analyze text length and content (mock AI analysis)
  const totalText = [
    ...retrospective.keeps,
    ...retrospective.problems,
    ...retrospective.tries,
  ].join(' ');

  if (totalText.length > 200) score += 5; // Detailed reflection bonus

  return Math.min(Math.round(score), 100);
}

// Get icon and color based on insight type and category
function getInsightStyle(insight: AIInsight) {
  const typeMap = {
    pattern: { icon: AlertCircle, color: 'text-amber-600' },
    suggestion: { icon: Lightbulb, color: 'text-blue-600' },
    achievement: { icon: Sparkles, color: 'text-green-600' },
    warning: { icon: AlertCircle, color: 'text-red-600' },
  };

  // Override color based on category
  if (insight.category === 'strength') {
    return { icon: typeMap[insight.type].icon, color: 'text-green-600' };
  } else if (insight.category === 'growth') {
    return { icon: typeMap[insight.type].icon, color: 'text-amber-600' };
  }

  return typeMap[insight.type];
}

export function Dashboard({ retrospectives, onNewRetrospective }: DashboardProps) {
  const [timeRange, setTimeRange] = useState<'30d' | '90d' | 'all'>('30d');
  const [insights, setInsights] = useState<AIInsight[]>([]);
  const [loadingInsights, setLoadingInsights] = useState(false);
  const insightsFetchedRef = useRef(false);

  // Calculate wellbeing trend
  const wellbeingData: WellbeingData[] = retrospectives
    .slice(0, timeRange === '30d' ? 4 : timeRange === '90d' ? 12 : retrospectives.length)
    .reverse()
    .map((retro) => ({
      date: retro.date,
      score: calculateWellbeingScore(retro),
      label: new Date(retro.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
    }));

  const currentScore = wellbeingData.length > 0 ? wellbeingData[wellbeingData.length - 1].score : 0;
  const avgScore = wellbeingData.length > 0
    ? Math.round(wellbeingData.reduce((sum, d) => sum + d.score, 0) / wellbeingData.length)
    : 0;

  const recentRetros = retrospectives.slice(0, 3);

  // Fetch AI insights when retrospectives change
  useEffect(() => {
    async function fetchInsights() {
      // Only fetch if we have at least 1 retrospective and haven't fetched yet
      if (retrospectives.length === 0 || insightsFetchedRef.current) return;

      setLoadingInsights(true);
      insightsFetchedRef.current = true;

      try {
        const response = await fetch('/api/ai/insights', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ retrospectives }),
        });

        if (!response.ok) {
          throw new Error('Failed to fetch insights');
        }

        const data = await response.json();
        setInsights(data.insights);
      } catch (error) {
        console.error('Error fetching AI insights:', error);
        toast.error('Unable to load AI insights at this time');
        setInsights([]);
      } finally {
        setLoadingInsights(false);
      }
    }

    fetchInsights();
  }, [retrospectives.length]); // Re-fetch when retrospectives count changes

  // Stats
  const totalRetrospectives = retrospectives.length;
  const totalActions = retrospectives.flatMap(r => r.actions).length;
  const completedActions = retrospectives.flatMap(r => r.actions).filter(a => a.completed).length;
  const completionRate = totalActions > 0 ? Math.round((completedActions / totalActions) * 100) : 0;

  return (
    <div className="space-y-6">
      {/* Welcome Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-slate-900">Your Growth Overview</h2>
          <p className="text-slate-600">Track progress and insights</p>
        </div>
        <Button onClick={onNewRetrospective} className="bg-blue-600 hover:bg-blue-700">
          <Plus className="w-4 h-4 mr-2" />
          New Retrospective
        </Button>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="bg-gradient-to-br from-blue-50 to-blue-100 border-blue-200">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-blue-700 mb-1">Current Wellbeing</p>
                <p className="text-3xl font-bold text-slate-900">{currentScore}/100</p>
              </div>
              <div className="w-12 h-12 rounded-full bg-blue-200 flex items-center justify-center">
                <TrendingUp className="w-6 h-6 text-blue-700" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-purple-50 to-purple-100 border-purple-200">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-purple-700 mb-1">Avg Score</p>
                <p className="text-3xl font-bold text-slate-900">{avgScore}/100</p>
              </div>
              <div className="w-12 h-12 rounded-full bg-purple-200 flex items-center justify-center">
                <Brain className="w-6 h-6 text-purple-700" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-green-50 to-green-100 border-green-200">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-green-700 mb-1">Action Rate</p>
                <p className="text-3xl font-bold text-slate-900">{completionRate}%</p>
              </div>
              <div className="w-12 h-12 rounded-full bg-green-200 flex items-center justify-center">
                <Sparkles className="w-6 h-6 text-green-700" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-amber-50 to-amber-100 border-amber-200">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-amber-700 mb-1">Total Sessions</p>
                <p className="text-3xl font-bold text-slate-900">{totalRetrospectives}</p>
              </div>
              <div className="w-12 h-12 rounded-full bg-amber-200 flex items-center justify-center">
                <Calendar className="w-6 h-6 text-amber-700" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Wellbeing Trend Chart */}
      <Card className="bg-white/60 backdrop-blur-sm border-slate-200">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Wellbeing Score Over Time</CardTitle>
              <CardDescription>Track your emotional wellbeing trend</CardDescription>
            </div>
            <div className="flex gap-2">
              <Button
                variant={timeRange === '30d' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setTimeRange('30d')}
                className={timeRange === '30d' ? 'bg-blue-600' : ''}
              >
                30D
              </Button>
              <Button
                variant={timeRange === '90d' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setTimeRange('90d')}
                className={timeRange === '90d' ? 'bg-blue-600' : ''}
              >
                90D
              </Button>
              <Button
                variant={timeRange === 'all' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setTimeRange('all')}
                className={timeRange === 'all' ? 'bg-blue-600' : ''}
              >
                All
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {wellbeingData.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={wellbeingData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="label" stroke="#64748b" />
                <YAxis domain={[0, 100]} stroke="#64748b" />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid #e2e8f0',
                    borderRadius: '8px',
                  }}
                />
                <Line
                  type="monotone"
                  dataKey="score"
                  stroke="#3b82f6"
                  strokeWidth={3}
                  dot={{ fill: '#3b82f6', r: 6 }}
                  activeDot={{ r: 8 }}
                />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="text-center py-12 text-slate-500">
              No data yet. Create your first retrospective to start tracking!
            </div>
          )}
        </CardContent>
      </Card>

      {/* AI Insights */}
      {(insights.length > 0 || loadingInsights) && (
        <Card className="bg-white/60 backdrop-blur-sm border-slate-200">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-purple-600" />
              AI Insights
              {loadingInsights && <Loader2 className="w-4 h-4 animate-spin text-blue-600" />}
            </CardTitle>
            <CardDescription>Powered by Gemini AI - Personalized insights from your retrospectives</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {loadingInsights ? (
              <div className="text-center py-8 text-slate-500">
                <Loader2 className="w-8 h-8 animate-spin mx-auto mb-2 text-blue-600" />
                <p>Analyzing your retrospectives with AI...</p>
              </div>
            ) : (
              insights.map((insight, index) => {
                const { icon: Icon, color } = getInsightStyle(insight);
                return (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.3, delay: index * 0.1 }}
                    className="flex gap-4 p-4 rounded-lg bg-slate-50 border border-slate-200 hover:border-blue-300 transition-all"
                  >
                    <div className={`${color} mt-1`}>
                      <Icon className="w-5 h-5" />
                    </div>
                    <div className="flex-1">
                      <h4 className={`${color} font-semibold mb-1`}>{insight.title}</h4>
                      <p className="text-sm text-slate-600">{insight.description}</p>
                    </div>
                    <div className="flex flex-col gap-1 items-end">
                      <Badge variant="secondary" className="h-fit capitalize">
                        {insight.type}
                      </Badge>
                      {insight.category && (
                        <Badge
                          variant="outline"
                          className={`h-fit text-xs ${
                            insight.category === 'strength' ? 'border-green-300 text-green-700' : 'border-amber-300 text-amber-700'
                          }`}
                        >
                          {insight.category}
                        </Badge>
                      )}
                    </div>
                  </motion.div>
                );
              })
            )}
          </CardContent>
        </Card>
      )}

      {/* Recent Retrospectives Summary */}
      {recentRetros.length > 0 && (
        <Card className="bg-white/60 backdrop-blur-sm border-slate-200">
          <CardHeader>
            <CardTitle>Recent Retrospectives</CardTitle>
            <CardDescription>Quick overview of your latest reflections</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {recentRetros.map((retro, index) => {
              const score = calculateWellbeingScore(retro);
              return (
                <motion.div
                  key={retro.id}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ duration: 0.3, delay: index * 0.1 }}
                  className="p-4 rounded-lg border border-slate-200 bg-white hover:shadow-md transition-shadow"
                >
                  <div className="flex items-start justify-between mb-3">
                    <div>
                      <div className="font-semibold text-slate-900 mb-1">
                        {retro.title || new Date(retro.date).toLocaleDateString('en-US', {
                          month: 'long',
                          day: 'numeric',
                          year: 'numeric',
                        })}
                      </div>
                      <div className="flex gap-3 text-sm text-slate-500">
                        <span className="text-green-600">{retro.keeps.length} Keeps</span>
                        <span className="text-red-600">{retro.problems.length} Problems</span>
                        <span className="text-blue-600">{retro.actions.length} Actions</span>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-xs text-slate-500 mb-1">Score</div>
                      <div className={`text-lg font-bold ${score >= 70 ? 'text-green-600' : score >= 50 ? 'text-amber-600' : 'text-red-600'}`}>
                        {score}/100
                      </div>
                    </div>
                  </div>
                  <Progress value={score} className="h-2" />
                </motion.div>
              );
            })}
          </CardContent>
        </Card>
      )}
    </div>
  );
}
