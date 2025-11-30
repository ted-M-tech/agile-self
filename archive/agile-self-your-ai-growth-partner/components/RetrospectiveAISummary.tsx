'use client'

import { useState } from 'react'
import Icon from './Icon'

type RetrospectiveAISummaryProps = {
  retrospectiveId: string
  userId: string
}

type Summary = {
  summary: string
  keyInsights: string[]
  sentiment: 'positive' | 'neutral' | 'negative' | 'mixed'
}

type Suggestion = {
  type: 'try' | 'action'
  text: string
  reasoning: string
}

export default function RetrospectiveAISummary({ retrospectiveId, userId }: RetrospectiveAISummaryProps) {
  const [loading, setLoading] = useState(false)
  const [summary, setSummary] = useState<Summary | null>(null)
  const [suggestions, setSuggestions] = useState<Suggestion[]>([])
  const [error, setError] = useState<string | null>(null)
  const [activeView, setActiveView] = useState<'summary' | 'suggestions'>('summary')

  const generateSummary = async () => {
    setLoading(true)
    setError(null)
    try {
      const response = await fetch('/api/ai/summarize', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ retrospectiveId, userId })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to generate summary')
      }

      setSummary(data)
      setActiveView('summary')
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const generateSuggestions = async () => {
    setLoading(true)
    setError(null)
    try {
      const response = await fetch('/api/ai/suggestions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ retrospectiveId, userId })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to generate suggestions')
      }

      setSuggestions(data.suggestions)
      setActiveView('suggestions')
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const getSentimentColor = (sentiment: string) => {
    switch (sentiment) {
      case 'positive': return 'text-ios-green'
      case 'negative': return 'text-ios-red'
      case 'mixed': return 'text-ios-orange'
      default: return 'text-ios-gray-1'
    }
  }

  const getSentimentIcon = (sentiment: string): 'checkmark.circle.fill' | 'xmark.circle.fill' | 'star' => {
    switch (sentiment) {
      case 'positive': return 'checkmark.circle.fill'
      case 'negative': return 'xmark.circle.fill'
      case 'mixed': return 'star'
      default: return 'star'
    }
  }

  return (
    <div className="card">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center space-x-3">
          <div className="p-2 rounded-xl bg-gradient-to-br from-ios-teal/10 to-ios-blue/10">
            <Icon name="sparkles" size={24} className="text-ios-teal" />
          </div>
          <div>
            <h3 className="text-ios-title-3 text-ios-label-primary">AI Assistant</h3>
            <p className="text-ios-footnote text-ios-label-secondary">
              Smart insights for this session
            </p>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex space-x-2 mb-6">
        <button
          onClick={generateSummary}
          disabled={loading}
          className="flex-1 btn btn-outline btn-sm flex items-center justify-center space-x-2"
        >
          <Icon name="doc.text" size={16} />
          <span>Summary</span>
        </button>
        <button
          onClick={generateSuggestions}
          disabled={loading}
          className="flex-1 btn btn-outline btn-sm flex items-center justify-center space-x-2"
        >
          <Icon name="lightbulb" size={16} />
          <span>Suggestions</span>
        </button>
      </div>

      {/* Loading State */}
      {loading && (
        <div className="text-center py-8">
          <div className="inline-flex items-center justify-center w-12 h-12 mb-3">
            <div className="w-8 h-8 border-3 border-ios-blue/30 border-t-ios-blue rounded-full animate-spin" />
          </div>
          <p className="text-ios-footnote text-ios-label-secondary">
            AI is analyzing...
          </p>
        </div>
      )}

      {/* Error Message */}
      {error && (
        <div className="mb-4 p-4 bg-ios-red/10 border border-ios-red/20 rounded-xl">
          <p className="text-ios-body text-ios-red">{error}</p>
        </div>
      )}

      {/* Summary View */}
      {!loading && activeView === 'summary' && summary && (
        <div className="space-y-4 animate-fade-in">
          {/* Sentiment Badge */}
          <div className="flex items-center justify-between p-3 bg-ios-gray-6 rounded-xl">
            <span className="text-ios-subheadline text-ios-label-secondary">Sentiment</span>
            <div className="flex items-center space-x-2">
              <Icon
                name={getSentimentIcon(summary.sentiment)}
                size={18}
                className={getSentimentColor(summary.sentiment)}
              />
              <span className={`text-ios-subheadline font-semibold capitalize ${getSentimentColor(summary.sentiment)}`}>
                {summary.sentiment}
              </span>
            </div>
          </div>

          {/* Summary */}
          <div className="p-4 bg-gradient-to-br from-ios-blue/5 to-ios-teal/5 rounded-xl border border-ios-blue/10">
            <h4 className="text-ios-headline text-ios-label-primary mb-2 flex items-center space-x-2">
              <Icon name="doc.text" size={16} className="text-ios-blue" />
              <span>Summary</span>
            </h4>
            <p className="text-ios-body text-ios-label-primary leading-relaxed">
              {summary.summary}
            </p>
          </div>

          {/* Key Insights */}
          {summary.keyInsights.length > 0 && (
            <div>
              <h4 className="text-ios-headline text-ios-label-primary mb-3 flex items-center space-x-2">
                <Icon name="lightbulb.fill" size={16} className="text-ios-orange" />
                <span>Key Insights</span>
              </h4>
              <div className="space-y-2">
                {summary.keyInsights.map((insight, idx) => (
                  <div key={idx} className="flex items-start space-x-3 p-3 bg-ios-gray-6 rounded-xl">
                    <div className="flex-shrink-0 w-5 h-5 rounded-full bg-ios-orange/20 flex items-center justify-center mt-0.5">
                      <span className="text-ios-caption2 font-bold text-ios-orange">{idx + 1}</span>
                    </div>
                    <p className="text-ios-body text-ios-label-primary flex-1">
                      {insight}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Suggestions View */}
      {!loading && activeView === 'suggestions' && suggestions.length > 0 && (
        <div className="space-y-3 animate-fade-in">
          <h4 className="text-ios-headline text-ios-label-primary mb-3 flex items-center space-x-2">
            <Icon name="lightbulb.fill" size={18} className="text-ios-yellow" />
            <span>AI Suggestions</span>
          </h4>
          {suggestions.map((suggestion, idx) => (
            <div key={idx} className="p-4 bg-gradient-to-br from-ios-yellow/5 to-ios-orange/5 rounded-xl border border-ios-yellow/20">
              <div className="flex items-start space-x-3 mb-2">
                <div className="flex-shrink-0 w-6 h-6 rounded-full bg-ios-yellow/20 flex items-center justify-center mt-0.5">
                  <Icon name="sparkles" size={12} className="text-ios-yellow" />
                </div>
                <p className="text-ios-subheadline font-semibold text-ios-label-primary flex-1">
                  {suggestion.text}
                </p>
              </div>
              <p className="text-ios-footnote text-ios-label-secondary ml-9">
                {suggestion.reasoning}
              </p>
            </div>
          ))}
        </div>
      )}

      {/* Empty State */}
      {!loading && !error && !summary && suggestions.length === 0 && (
        <div className="text-center py-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-ios-teal/10 mb-3">
            <Icon name="sparkles" size={32} className="text-ios-teal" />
          </div>
          <p className="text-ios-body text-ios-label-secondary mb-1">
            Get AI-powered insights
          </p>
          <p className="text-ios-footnote text-ios-label-tertiary">
            Click Summary or Suggestions above
          </p>
        </div>
      )}
    </div>
  )
}
