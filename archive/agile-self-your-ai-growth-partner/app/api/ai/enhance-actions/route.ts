import { NextRequest, NextResponse } from 'next/server';
import { enhanceActionItems } from '@/lib/ai/gemini-service';

export async function POST(request: NextRequest) {
  try {
    const { tryItems } = await request.json();

    if (!tryItems || !Array.isArray(tryItems) || tryItems.length === 0) {
      return NextResponse.json(
        { error: 'Try items array is required' },
        { status: 400 }
      );
    }

    const enhanced = await enhanceActionItems(tryItems);

    return NextResponse.json({ enhanced });
  } catch (error) {
    console.error('Error enhancing action items:', error);
    return NextResponse.json(
      { error: 'Failed to enhance action items' },
      { status: 500 }
    );
  }
}
