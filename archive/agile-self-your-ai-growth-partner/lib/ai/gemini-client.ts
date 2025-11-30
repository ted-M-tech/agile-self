import { GoogleGenerativeAI } from '@google/generative-ai';

const apiKey = process.env.GEMINI_API_KEY;

if (!apiKey) {
  console.error('❌ GEMINI_API_KEY is not set in environment variables');
  console.error('Please add GEMINI_API_KEY to your .env.local file');
}

let genAI: GoogleGenerativeAI | null = null;
let model: any = null;

try {
  if (apiKey) {
    genAI = new GoogleGenerativeAI(apiKey);

    // Use Gemini 2.0 Flash (latest stable, fast and cost-effective)
    model = genAI.getGenerativeModel({
      model: 'gemini-2.0-flash',
      generationConfig: {
        temperature: 0.7,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 1024,
      },
    });

    console.log('✅ Gemini AI initialized successfully with model: gemini-2.0-flash');
  }
} catch (error) {
  console.error('❌ Error initializing Gemini AI:', error);
}

export { genAI, model };
