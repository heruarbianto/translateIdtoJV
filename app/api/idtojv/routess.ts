import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';
import natural from 'natural';  // Untuk stemming

const prisma = new PrismaClient();

// Fungsi stemming
const stemmer = natural.PorterStemmer;

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

    // Normalisasi dan stemming setiap kata
    const normalizedWords = words.map(word => {
      const cleanWord = word.replace(/[,;.!?]/g, '').trim();
      return stemmer.stem(cleanWord); // Melakukan stemming
    });

    const translatedWords = await Promise.all(
      normalizedWords.map(async (word) => {
        // Cari padanan yang cocok
        let translation = await prisma.kamusJawaIndonesia.findFirst({
          where: {
            Makna_indonesia: {
              equals: word,
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
                contains: word,
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
