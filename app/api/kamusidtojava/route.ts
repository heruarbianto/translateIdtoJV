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
    // Memecah kalimat menjadi kata-kata
    const words = sentence.split(/\s+/);

    // Menerjemahkan setiap kata
    const translatedWords = await Promise.all(
      words.map(async (word) => {
        // Membersihkan kata dari tanda baca untuk pencarian
        const cleanWord = word.replace(/[,;.!?]/g, '').trim();
        
        // Jika kata kosong (misalnya tanda baca), kembalikan objek dengan kata asli
        if (!cleanWord) {
          return {
            original: word,
            translated: word,
            matched: null,
          };
        }

        // Cari terjemahan di database dengan pencocokan yang lebih spesifik
        const translation = await prisma.kamusJawaIndonesia.findFirst({
          where: {
            indonesia: {
              // Menggunakan equals untuk kata tunggal
              equals: cleanWord,
            },
          },
          select: {
            jawa: true,
            indonesia: true,
          },
        }) || await prisma.kamusJawaIndonesia.findFirst({
          where: {
            indonesia: {
              contains: cleanWord,
            },
          },
          select: {
            jawa: true,
            indonesia: true,
          },
        });

        // Jika ditemukan, kembalikan kata Jawa tanpa kode dalam tanda kurung
        // Jika tidak, kembalikan kata asli
        const translatedWord = translation?.jawa
          ? translation.jawa.replace(/\s*\([^)]*\)/g, '').replace(/[-;]/g, '').trim()
          : word;

        return {
          original: word,
          translated: translatedWord,
          matched: translation?.indonesia || null,
        };
      })
    );

    // Menggabungkan kata-kata menjadi kalimat
    const translatedSentence = translatedWords.map(w => w.translated).join(' ');

    return NextResponse.json({
      original: sentence,
      translated: translatedSentence,
      details: translatedWords, // Untuk debugging
    }, { status: 200 });

  } catch (error) {
    console.error('Error during translation:', error);
    return NextResponse.json(
      { error: 'Terjadi kesalahan saat menerjemahkan' },
      { status: 500 }
    );
  }
}