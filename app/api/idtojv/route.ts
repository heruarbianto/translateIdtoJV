import { NextRequest, NextResponse } from 'next/server';

const VALID_PAIRS = {
  id: ['ng', 'kl', 'ka'],
  jw: ['id']
};

const isImbuhan = (word: string): boolean => {
  const prefix = ['me', 'mem', 'men', 'meng', 'di', 'ke', 'ber', 'ter', 'pe', 'se'];
  const suffix = ['kan', 'an', 'i', 'lah', 'kah', 'nya'];
  return prefix.some(p => word.startsWith(p)) || suffix.some(s => word.endsWith(s));
};

const stemming = (word: string): string => {
  // Stemming sangat sederhana (untuk demonstrasi)
  let result = word;
  const prefixes = ['memper', 'meng', 'meny', 'men', 'mem', 'me', 'ber', 'ter', 'per', 'di', 'ke', 'se'];
  const suffixes = ['kan', 'an', 'i', 'lah', 'kah', 'nya'];

  for (const pre of prefixes) {
    if (result.startsWith(pre)) {
      result = result.slice(pre.length);
      break;
    }
  }

  for (const suf of suffixes) {
    if (result.endsWith(suf)) {
      result = result.slice(0, -suf.length);
      break;
    }
  }

  return result;
};

const tokenize = (text: string): string[] => {
  return text.trim().toLowerCase().split(/\s+/);
};

const translateWord = async (text: string, from: string, to: string): Promise<string> => {
  const res = await fetch('https://api.translatejawa.id/translate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text, from, to })
  });

  const data = await res.json();
  return data.result || '';
};

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { text, from, to } = body;

    if (!text || !from || !to) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    const validTargets = VALID_PAIRS[from as keyof typeof VALID_PAIRS];
    if (!validTargets || !validTargets.includes(to)) {
      return NextResponse.json({ error: 'Invalid language pair' }, { status: 400 });
    }

    const tokens = tokenize(text);

    const word_analysis = await Promise.all(tokens.map(async (token) => {
      const translate_original = await translateWord(token, from, to);

      if (from === 'id') {
        const stemmed = stemming(token);
        const translate_stemmed = await translateWord(stemmed, from, to);

        return {
          original: token,
          translate_original,
          hasAffix: isImbuhan(token),
          stemmed,
          translate_stemmed
        };
      } else {
        return {
          original: token,
          translate_original
        };
      }
    }));

    const stemmed_text = from === 'id' ? word_analysis.map(w => (w as any).stemmed).join(' ') : undefined;

    // Terjemahan kalimat penuh
    const fullRes = await fetch('https://api.translatejawa.id/translate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text, from, to })
    });

    const originalData = await fullRes.json();

    return NextResponse.json({
      translation_original: originalData.result,
      analysis: {
        tokens,
        word_analysis,
        ...(stemmed_text && { stemmed_text })
      }
    }, { status: 200 });

  } catch (error) {
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
