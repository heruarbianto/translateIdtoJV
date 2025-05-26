import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

interface TranslateRequest {
  sentence: string;
}

export async function POST(request: NextRequest) {
  try {
    const body: TranslateRequest = await request.json();

    if (!body.sentence || typeof body.sentence !== 'string') {
      return NextResponse.json(
        { error: 'Kalimat yang akan diterjemahkan harus berupa string' },
        { status: 400 }
      );
    }

    const sentence = body.sentence.trim().toLowerCase();
    const words = sentence.split(/\s+/);

    const translatedWords = await Promise.all(
      words.map(async (word) => {
        const cleanWord = word.replace(/[,;.!?]/g, '').trim();

        if (!cleanWord) {
          return {
            original: word,
            translated: word,
            matched: null,
          };
        }

        // Cari padanan yang cocok (prioritas exact match, lalu contains)
        let translation = await prisma.kamusJawaIndonesia.findFirst({
          where: {
            Makna_indonesia: {
              equals: cleanWord,
            },
          },
          select: {
            jawa: true,
            Makna_indonesia: true,
          },
        });

        // Jika belum ketemu, coba cari yang mengandung kata tsb
        if (!translation) {
          translation = await prisma.kamusJawaIndonesia.findFirst({
            where: {
              Makna_indonesia: {
                contains: cleanWord,
              },
            },
            select: {
              jawa: true,
              Makna_indonesia: true,
            },
          });
        }

        const translatedWord = translation?.jawa
          ? translation.jawa.replace(/\s*\([^)]*\)/g, '').replace(/[-;]/g, '').trim()
          : word;

        return {
          original: word,
          translated: translatedWord,
          matched: translation?.Makna_indonesia || null,
        };
      })
    );

    const translatedSentence = translatedWords.map(w => w.translated).join(' ');

    return NextResponse.json({
      original: sentence,
      translated: translatedSentence,
      details: translatedWords,
    }, { status: 200 });

  } catch (error) {
    console.error('Error during translation:', error);
    return NextResponse.json(
      { error: 'Terjadi kesalahan saat menerjemahkan' },
      { status: 500 }
    );
  }
}
