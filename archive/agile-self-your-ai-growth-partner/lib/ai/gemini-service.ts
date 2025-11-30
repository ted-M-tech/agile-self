import { model } from './gemini-client';
import type { Retrospective } from '@/lib/types';

// Check if model is initialized
function checkModelAvailability() {
  if (!model) {
    throw new Error('Gemini AI is not initialized. Please check your GEMINI_API_KEY in .env.local');
  }
}

export interface AIInsight {
  type: 'pattern' | 'suggestion' | 'achievement' | 'warning';
  title: string;
  description: string;
  category?: 'strength' | 'growth';
}

export interface TrySuggestion {
  text: string;
  rationale: string;
  relatedProblems: number[];
}

/**
 * Generate personalized Try suggestions based on Problems
 */
export async function generateTrySuggestions(
  problems: string[],
  keeps: string[] = [],
  pastRetros?: Retrospective[]
): Promise<TrySuggestion[]> {
  checkModelAvailability();

  if (problems.length === 0) {
    return [];
  }

  const context = pastRetros
    ? `\n\nPast context (for reference):\n${pastRetros
        .slice(0, 3)
        .map((r, i) => `Retro ${i + 1}: Problems: ${r.problems.join(', ')}`)
        .join('\n')}`
    : '';

  const prompt = `You are a personal growth coach helping someone with their self-retrospective using the KPTA framework.

Based on these Problems they're facing:
${problems.map((p, i) => `${i + 1}. ${p}`).join('\n')}

${keeps.length > 0 ? `\nThings they want to Keep doing:\n${keeps.map((k, i) => `${i + 1}. ${k}`).join('\n')}` : ''}${context}

Generate 3-5 specific, actionable "Try" suggestions. Each suggestion should:
- Be concrete and specific (not vague like "be more organized")
- Be achievable within 1-2 weeks
- Address one or more of the problems
- Build on their strengths (Keeps) when possible

Return ONLY a JSON array in this exact format:
[
  {
    "text": "Try the Pomodoro technique: 25min focused work, 5min break",
    "rationale": "Helps with focus and procrastination issues",
    "relatedProblems": [0, 2]
  }
]

Return pure JSON only, no markdown, no explanation.`;

  try {
    const result = await model.generateContent(prompt);
    const response = result.response.text();

    // Clean up markdown code blocks if present
    const jsonText = response
      .replace(/```json\n?/g, '')
      .replace(/```\n?/g, '')
      .trim();

    const suggestions = JSON.parse(jsonText);
    return suggestions.slice(0, 5); // Limit to 5 suggestions
  } catch (error) {
    console.error('Error generating Try suggestions:', error);
    throw new Error('Failed to generate AI suggestions');
  }
}

/**
 * Generate AI-powered insights from retrospectives
 */
export async function generateAIInsights(
  retrospectives: Retrospective[]
): Promise<AIInsight[]> {
  checkModelAvailability();

  if (retrospectives.length === 0) {
    return [];
  }

  const recentRetros = retrospectives.slice(0, 5);

  const prompt = `You are analyzing personal retrospectives to provide growth insights.

Recent retrospectives data:
${recentRetros
  .map(
    (r, i) => `
Retrospective ${i + 1} (${r.type}, ${new Date(r.date).toLocaleDateString()}):
- Keeps: ${r.keeps.join('; ')}
- Problems: ${r.problems.join('; ')}
- Tries: ${r.tries.join('; ')}
- Actions completed: ${r.actions.filter(a => a.completed).length}/${r.actions.length}
`
  )
  .join('\n')}

Analyze these retrospectives and provide 3-5 insights. Look for:
1. Recurring patterns (problems that appear multiple times)
2. Strengths to celebrate (consistent Keeps, high action completion)
3. Growth opportunities (areas needing attention)
4. Trends over time (improving or declining)

Categorize insights as:
- "strength" for positive patterns and achievements
- "growth" for areas needing improvement

Return ONLY a JSON array in this exact format:
[
  {
    "type": "pattern",
    "title": "Recurring Theme Title",
    "description": "Specific insight with actionable context",
    "category": "growth"
  }
]

Types: "pattern", "suggestion", "achievement", "warning"
Return pure JSON only, no markdown.`;

  try {
    const result = await model.generateContent(prompt);
    const response = result.response.text();

    const jsonText = response
      .replace(/```json\n?/g, '')
      .replace(/```\n?/g, '')
      .trim();

    const insights = JSON.parse(jsonText);
    return insights.slice(0, 5);
  } catch (error) {
    console.error('Error generating AI insights:', error);
    throw new Error('Failed to generate AI insights');
  }
}

/**
 * Analyze sentiment and wellbeing from a retrospective
 */
export async function analyzeSentiment(retro: Retrospective): Promise<{
  score: number; // 0-100
  trend: 'improving' | 'stable' | 'declining';
  summary: string;
}> {
  checkModelAvailability();

  const prompt = `Analyze the emotional tone and wellbeing in this retrospective:

Keeps (what went well): ${retro.keeps.join('; ')}
Problems (challenges): ${retro.problems.join('; ')}
Tries (experiments): ${retro.tries.join('; ')}

Return a wellbeing score (0-100) and brief summary.
Return ONLY valid JSON in this format:
{
  "score": 75,
  "trend": "stable",
  "summary": "Overall positive with some challenges. Taking proactive steps."
}

Trend options: "improving", "stable", "declining"
Return pure JSON only.`;

  try {
    const result = await model.generateContent(prompt);
    const response = result.response.text();

    const jsonText = response
      .replace(/```json\n?/g, '')
      .replace(/```\n?/g, '')
      .trim();

    return JSON.parse(jsonText);
  } catch (error) {
    console.error('Error analyzing sentiment:', error);
    // Return neutral fallback
    return {
      score: 50,
      trend: 'stable',
      summary: 'Unable to analyze sentiment at this time.',
    };
  }
}

/**
 * Generate improved action items from Try items
 */
export async function enhanceActionItems(tryItems: string[]): Promise<
  Array<{
    original: string;
    enhanced: string;
    reasoning: string;
  }>
> {
  checkModelAvailability();

  if (tryItems.length === 0) return [];

  const prompt = `These are action items that need to be more specific and measurable:

${tryItems.map((t, i) => `${i + 1}. ${t}`).join('\n')}

For each item, create an enhanced version that is:
- More specific and concrete
- Measurable or has clear completion criteria
- Time-bound when appropriate
- Still achievable

Return ONLY a JSON array:
[
  {
    "original": "Be more organized",
    "enhanced": "Spend 10 minutes each Sunday planning the week in a planner",
    "reasoning": "Added specific time commitment and concrete action"
  }
]

Return pure JSON only.`;

  try {
    const result = await model.generateContent(prompt);
    const response = result.response.text();

    const jsonText = response
      .replace(/```json\n?/g, '')
      .replace(/```\n?/g, '')
      .trim();

    return JSON.parse(jsonText);
  } catch (error) {
    console.error('Error enhancing action items:', error);
    return [];
  }
}
