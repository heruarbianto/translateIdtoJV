// Untuk Next.js App Router (Next 13+)
import { NextRequest, NextResponse } from 'next/server';

const VALID_PAIRS = {
  id: ['ng', 'kl', 'ka'],
  jw: ['id']
};

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { text, from, to } = body;

    // Validasi parameter
    if (!text || !from || !to) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    // Cek apakah kombinasi from-to valid
    const validTargets = VALID_PAIRS[from as keyof typeof VALID_PAIRS];
    if (!validTargets || !validTargets.includes(to)) {
      return NextResponse.json({ error: 'Invalid language pair' }, { status: 400 });
    }

    // Forward ke API utama
    const res = await fetch('https://api.translatejawa.id/translate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text, from, to })
    });

    const data = await res.json();

    return NextResponse.json(data, { status: res.status });

  } catch (error) {
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
