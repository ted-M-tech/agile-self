import { NextRequest, NextResponse } from 'next/server';
import { generateAIInsights } from '@/lib/ai/gemini-service';
import type { Retrospective } from '@/lib/types';

export async function POST(request: NextRequest) {
  try {
    const { retrospectives } = await request.json();

    if (!retrospectives || !Array.isArray(retrospectives)) {
      return NextResponse.json(
        { error: 'Invalid retrospectives data' },
        { status: 400 }
      );
    }

    const insights = await generateAIInsights(retrospectives);

    return NextResponse.json({ insights });
  } catch (error) {
    console.error('Error generating AI insights:', error);
    return NextResponse.json(
      { error: 'Failed to generate insights' },
      { status: 500 }
    );
  }
}
