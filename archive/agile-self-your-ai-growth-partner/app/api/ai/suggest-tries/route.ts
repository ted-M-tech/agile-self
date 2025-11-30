import { NextRequest, NextResponse } from 'next/server';
import { generateTrySuggestions } from '@/lib/ai/gemini-service';

export async function POST(request: NextRequest) {
  try {
    const { problems, keeps, pastRetros } = await request.json();

    if (!problems || !Array.isArray(problems) || problems.length === 0) {
      return NextResponse.json(
        { error: 'Problems array is required' },
        { status: 400 }
      );
    }

    const suggestions = await generateTrySuggestions(
      problems,
      keeps || [],
      pastRetros
    );

    return NextResponse.json({ suggestions });
  } catch (error) {
    console.error('Error generating Try suggestions:', error);
    return NextResponse.json(
      { error: 'Failed to generate suggestions' },
      { status: 500 }
    );
  }
}
