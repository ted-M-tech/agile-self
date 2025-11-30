import { NextRequest, NextResponse } from 'next/server';
import { model } from '@/lib/ai/gemini-client';

export async function GET(request: NextRequest) {
  try {
    // Check if API key is loaded
    const hasApiKey = !!process.env.GEMINI_API_KEY;
    const isModelInitialized = !!model;

    if (!hasApiKey) {
      return NextResponse.json({
        status: 'error',
        message: 'GEMINI_API_KEY not found in environment variables',
        hasApiKey,
        isModelInitialized,
      }, { status: 500 });
    }

    if (!isModelInitialized) {
      return NextResponse.json({
        status: 'error',
        message: 'Gemini model failed to initialize',
        hasApiKey,
        isModelInitialized,
      }, { status: 500 });
    }

    // Try a simple test
    const result = await model.generateContent('Say "Hello" in one word.');
    const response = result.response.text();

    return NextResponse.json({
      status: 'success',
      message: 'Gemini AI is working!',
      hasApiKey,
      isModelInitialized,
      testResponse: response,
    });
  } catch (error: any) {
    return NextResponse.json({
      status: 'error',
      message: error.message || 'Unknown error',
      error: String(error),
    }, { status: 500 });
  }
}
