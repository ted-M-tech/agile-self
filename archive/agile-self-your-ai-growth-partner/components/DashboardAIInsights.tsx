'use client'

import { useEffect, useState, useCallback, useRef } from 'react'
import Icon from './Icon'

type AIInsightsProps = {
  userId: string
  retroCount: number
}

type CombinedInsights = {
  wellbeingScore: number
  wellbeingTrend: 'improving' | 'stable' | 'declining'
  topThemes: { theme: string; category: 'strength' | 'growth' }[]
  keyRecommendation: string
}

export default function DashboardAIInsights({ userId, retroCount }: AIInsightsProps) {
  const [insights, setInsights] = useState<CombinedInsights | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const loadingRef = useRef(false)
  const lastRetroCountRef = useRef<number | null>(null)

  const loadInsights = useCallback(async () => {
    // Safety check: Don't call API if user doesn't have enough retrospectives
    if (retroCount < 1) {
      console.log('⚠️ Skipping AI insights API call - need at least 1 retrospective (found:', retroCount, ')')
      setLoading(false)
      setInsights(null)
      return
    }

    // Prevent duplicate calls (for React StrictMode and rapid re-renders)
    if (loadingRef.current) {
      console.log('⏭️ Skipping duplicate AI insights API call (already loading)')
      return
    }

    // Skip if retroCount hasn't changed (prevents duplicate calls on re-render)
    if (lastRetroCountRef.current === retroCount) {
      console.log('⏭️ Skipping AI insights API call (retroCount unchanged)')
      return
    }

    loadingRef.current = true
    lastRetroCountRef.current = retroCount
    setLoading(true)
    setError(null)
    try {
      console.log('🔍 Loading AI insights for user:', userId, 'retroCount:', retroCount)

      // Use new cached insights API
      const response = await fetch('/api/ai/insights', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, limit: 10 })
      })

      const data = await response.json()

      if (response.ok) {
        setInsights({
          wellbeingScore: data.wellbeingScore || 50,
          wellbeingTrend: data.wellbeingTrend || 'stable',
          topThemes: data.topThemes?.slice(0, 3) || [],
          keyRecommendation: data.keyRecommendation || 'Keep reflecting regularly'
        })

        // Log if using cache
        if (data.cached) {
          console.log('✅ Loaded insights from cache (last updated:', data.cachedAt, ')')
        } else {
          console.log('✨ Generated fresh insights')
        }
      } else {
        // Log the specific error from API
        console.log('⚠️ AI Insights not available:', data.error)
        throw new Error(data.error || 'Failed to load insights')
      }
    } catch (err: any) {
      console.error('❌ Error loading AI insights:', err.message)
      setError(err.message)
    } finally {
      setLoading(false)
      loadingRef.current = false
    }
  }, [userId, retroCount])

  useEffect(() => {
    loadInsights()
  }, [loadInsights])

  if (loading) {
    return (
      <div className="card animate-fade-in">
        <div className="flex items-center space-x-3 mb-6">
          <div className="p-2 rounded-xl bg-gradient-to-br from-ios-purple/10 to-ios-pink/10">
            <Icon name="sparkles" size={24} className="text-ios-purple animate-pulse" />
          </div>
          <div>
            <h3 className="text-ios-title-3 text-ios-label-primary">AI Insights</h3>
            <p className="text-ios-footnote text-ios-label-secondary">Analyzing your progress...</p>
          </div>
        </div>

        {/* Skeleton Loading Animation */}
        <div className="space-y-6">
          {/* Well-being Score Skeleton */}
          <div className="p-6 bg-gradient-to-br from-ios-purple/5 to-ios-pink/5 rounded-2xl border border-ios-purple/10 animate-pulse">
            <div className="flex items-center justify-between">
              <div className="space-y-2">
                <div className="h-3 w-24 bg-ios-gray-5 rounded" />
                <div className="h-12 w-32 bg-ios-gray-5 rounded" />
              </div>
              <div className="space-y-2 text-right">
                <div className="h-3 w-16 bg-ios-gray-5 rounded ml-auto" />
                <div className="h-6 w-24 bg-ios-gray-5 rounded" />
              </div>
            </div>
          </div>

          {/* Patterns Skeleton */}
          <div className="space-y-3">
            <div className="h-4 w-32 bg-ios-gray-5 rounded" />
            <div className="space-y-2">
              <div className="h-12 bg-ios-gray-5 rounded-xl animate-pulse" />
              <div className="h-12 bg-ios-gray-5 rounded-xl animate-pulse delay-75" />
              <div className="h-12 bg-ios-gray-5 rounded-xl animate-pulse delay-150" />
            </div>
          </div>

          {/* Recommendation Skeleton */}
          <div className="p-4 bg-gradient-to-r from-ios-orange/5 to-ios-yellow/5 rounded-xl border border-ios-orange/10 animate-pulse">
            <div className="flex items-start space-x-3">
              <div className="w-5 h-5 bg-ios-gray-5 rounded-full mt-1" />
              <div className="flex-1 space-y-2">
                <div className="h-4 w-20 bg-ios-gray-5 rounded" />
                <div className="h-3 w-full bg-ios-gray-5 rounded" />
                <div className="h-3 w-3/4 bg-ios-gray-5 rounded" />
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (error) {
    // Don't show error UI, just silently fail
    // Error is already logged to console
    return null
  }

  // Show demo/preview when user doesn't have enough retrospectives
  if (!insights && retroCount < 1) {
    return (
      <div className="card animate-fade-in">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-3">
            <div className="p-2 rounded-xl bg-gradient-to-br from-ios-purple/10 to-ios-pink/10">
              <Icon name="sparkles" size={24} className="text-ios-purple" />
            </div>
            <div>
              <h3 className="text-ios-title-3 text-ios-label-primary">AI Insights</h3>
              <p className="text-ios-footnote text-ios-label-secondary">
                Unlock personalized growth insights
              </p>
            </div>
          </div>
        </div>

        {/* Locked Feature Preview */}
        <div className="relative">
          {/* Blurred Demo Content */}
          <div className="blur-sm pointer-events-none select-none opacity-60">
            {/* Demo Well-being Score */}
            <div className="mb-6 p-6 bg-gradient-to-br from-ios-purple/5 to-ios-pink/5 rounded-2xl border border-ios-purple/10">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-ios-caption1 text-ios-label-secondary mb-1">Well-being Score</p>
                  <div className="flex items-baseline space-x-2">
                    <span className="text-5xl font-bold text-ios-green">75</span>
                    <span className="text-ios-title-3 text-ios-label-tertiary">/100</span>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-ios-caption1 text-ios-label-secondary mb-1">Trend</p>
                  <div className="flex items-center justify-end space-x-1">
                    <Icon name="arrow.up" size={20} className="text-ios-green" />
                    <span className="text-ios-body font-semibold text-ios-green">
                      Improving
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Demo Patterns */}
            <div className="mb-6 space-y-4">
              {/* Demo Strengths */}
              <div>
                <div className="flex items-center space-x-2 mb-2">
                  <Icon name="star.fill" size={16} className="text-ios-green" />
                  <h4 className="text-ios-subheadline text-ios-label-primary font-semibold">Your Strengths</h4>
                </div>
                <div className="space-y-2">
                  <div className="flex items-center space-x-2 p-3 bg-gradient-to-r from-ios-green/5 to-ios-green/10 rounded-xl border border-ios-green/20">
                    <Icon name="checkmark.circle.fill" size={18} className="text-ios-green" />
                    <span className="text-ios-body text-ios-label-primary">Strong time management</span>
                  </div>
                  <div className="flex items-center space-x-2 p-3 bg-gradient-to-r from-ios-green/5 to-ios-green/10 rounded-xl border border-ios-green/20">
                    <Icon name="checkmark.circle.fill" size={18} className="text-ios-green" />
                    <span className="text-ios-body text-ios-label-primary">Effective communication</span>
                  </div>
                </div>
              </div>

              {/* Demo Growth Areas */}
              <div>
                <div className="flex items-center space-x-2 mb-2">
                  <Icon name="chart.bar" size={16} className="text-ios-blue" />
                  <h4 className="text-ios-subheadline text-ios-label-primary font-semibold">Growth Areas</h4>
                </div>
                <div className="space-y-2">
                  <div className="flex items-center space-x-2 p-3 bg-gradient-to-r from-ios-blue/5 to-ios-blue/10 rounded-xl border border-ios-blue/20">
                    <Icon name="arrow.up.circle.fill" size={18} className="text-ios-blue" />
                    <span className="text-ios-body text-ios-label-primary">Work-life balance</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Demo Recommendation */}
            <div className="p-4 bg-gradient-to-r from-ios-orange/5 to-ios-yellow/5 rounded-xl border border-ios-orange/10">
              <div className="flex items-start space-x-3">
                <Icon name="lightbulb.fill" size={20} className="text-ios-orange mt-0.5" />
                <div className="flex-1">
                  <h4 className="text-ios-subheadline font-semibold text-ios-orange mb-1">Focus Area</h4>
                  <p className="text-ios-body text-ios-label-primary leading-relaxed">
                    Focus on improving time management consistency
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Unlock Message Overlay */}
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="text-center bg-white/95 backdrop-blur-sm rounded-2xl p-8 shadow-xl border border-ios-purple/20 max-w-md mx-4">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-br from-ios-purple/20 to-ios-pink/20 mb-4">
                <Icon name="sparkles" size={32} className="text-ios-purple" />
              </div>
              <h3 className="text-ios-title-2 text-ios-label-primary font-bold mb-2">
                Unlock AI Insights
              </h3>
              <p className="text-ios-body text-ios-label-secondary mb-6 leading-relaxed">
                Complete your first retrospective to unlock AI insights.
              </p>
              <div className="flex items-center justify-center space-x-2 text-ios-subheadline text-ios-purple font-semibold">
                <span>{retroCount} / 1 retrospective</span>
                <div className="flex-1 max-w-[120px] h-2 bg-ios-gray-5 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-ios-purple to-ios-pink transition-all duration-500"
                    style={{ width: `${(retroCount / 1) * 100}%` }}
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (!insights) {
    return null
  }

  const getTrendIcon = (trend: string): 'arrow.up' | 'arrow.right' | 'arrow.down' => {
    switch (trend) {
      case 'improving': return 'arrow.up'
      case 'declining': return 'arrow.down'
      default: return 'arrow.right'
    }
  }

  const getTrendColor = (trend: string) => {
    switch (trend) {
      case 'improving': return 'text-ios-green'
      case 'declining': return 'text-ios-red'
      default: return 'text-ios-gray-1'
    }
  }

  const getTrendLabel = (trend: string) => {
    switch (trend) {
      case 'improving': return 'Improving'
      case 'declining': return 'Declining'
      default: return 'Stable'
    }
  }

  const getScoreColor = (score: number) => {
    if (score >= 70) return 'text-ios-green'
    if (score >= 40) return 'text-ios-orange'
    return 'text-ios-red'
  }

  return (
    <div className="card animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center space-x-3">
          <div className="p-2 rounded-xl bg-gradient-to-br from-ios-purple/10 to-ios-pink/10">
            <Icon name="sparkles" size={24} className="text-ios-purple" />
          </div>
          <div>
            <h3 className="text-ios-title-3 text-ios-label-primary">AI Insights</h3>
            <p className="text-ios-footnote text-ios-label-secondary">
              Based on your last {retroCount} retrospectives
            </p>
          </div>
        </div>
      </div>

      {/* Well-being Score - Large and Prominent */}
      <div className="mb-6 p-6 bg-gradient-to-br from-ios-purple/5 to-ios-pink/5 rounded-2xl border border-ios-purple/10">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-ios-caption1 text-ios-label-secondary mb-1">Well-being Score</p>
            <div className="flex items-baseline space-x-2">
              <span className={`text-5xl font-bold ${getScoreColor(insights.wellbeingScore)}`}>
                {insights.wellbeingScore}
              </span>
              <span className="text-ios-title-3 text-ios-label-tertiary">/100</span>
            </div>
          </div>
          <div className="text-right">
            <p className="text-ios-caption1 text-ios-label-secondary mb-1">Trend</p>
            <div className="flex items-center justify-end space-x-1">
              <Icon
                name={getTrendIcon(insights.wellbeingTrend)}
                size={20}
                className={getTrendColor(insights.wellbeingTrend)}
              />
              <span className={`text-ios-body font-semibold ${getTrendColor(insights.wellbeingTrend)}`}>
                {getTrendLabel(insights.wellbeingTrend)}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Strengths and Growth Areas */}
      {insights.topThemes.length > 0 && (
        <div className="mb-6 space-y-4">
          {/* Strengths */}
          {insights.topThemes.filter(t => t.category === 'strength').length > 0 && (
            <div>
              <div className="flex items-center space-x-2 mb-2">
                <Icon name="star.fill" size={16} className="text-ios-green" />
                <h4 className="text-ios-subheadline text-ios-label-primary font-semibold">Your Strengths</h4>
              </div>
              <div className="space-y-2">
                {insights.topThemes
                  .filter(t => t.category === 'strength')
                  .map((theme, idx) => (
                    <div key={idx} className="flex items-center space-x-2 p-3 bg-gradient-to-r from-ios-green/5 to-ios-green/10 rounded-xl border border-ios-green/20">
                      <Icon name="checkmark.circle.fill" size={18} className="text-ios-green flex-shrink-0" />
                      <span className="text-ios-body text-ios-label-primary">{theme.theme}</span>
                    </div>
                  ))}
              </div>
            </div>
          )}

          {/* Growth Areas */}
          {insights.topThemes.filter(t => t.category === 'growth').length > 0 && (
            <div>
              <div className="flex items-center space-x-2 mb-2">
                <Icon name="chart.bar" size={16} className="text-ios-blue" />
                <h4 className="text-ios-subheadline text-ios-label-primary font-semibold">Growth Areas</h4>
              </div>
              <div className="space-y-2">
                {insights.topThemes
                  .filter(t => t.category === 'growth')
                  .map((theme, idx) => (
                    <div key={idx} className="flex items-center space-x-2 p-3 bg-gradient-to-r from-ios-blue/5 to-ios-blue/10 rounded-xl border border-ios-blue/20">
                      <Icon name="arrow.up.circle.fill" size={18} className="text-ios-blue flex-shrink-0" />
                      <span className="text-ios-body text-ios-label-primary">{theme.theme}</span>
                    </div>
                  ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Key Recommendation */}
      {insights.keyRecommendation && (
        <div className="p-4 bg-gradient-to-r from-ios-orange/5 to-ios-yellow/5 rounded-xl border border-ios-orange/10">
          <div className="flex items-start space-x-3">
            <Icon name="lightbulb.fill" size={20} className="text-ios-orange mt-0.5" />
            <div className="flex-1">
              <h4 className="text-ios-subheadline font-semibold text-ios-orange mb-1">Focus Area</h4>
              <p className="text-ios-body text-ios-label-primary leading-relaxed">
                {insights.keyRecommendation}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
