import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const TranslateApp());
}

class TranslateApp extends StatelessWidget {
  const TranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MMC Translator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        cardTheme: CardThemeData( // Changed from CardTheme to CardThemeData
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias, // Added for smoother card edges
        ),
      ),
      home: const TranslateHomePage(),
    );
  }
}

class TranslateHomePage extends StatefulWidget {
  const TranslateHomePage({super.key});

  @override
  State<TranslateHomePage> createState() => _TranslateHomePageState();
}

class _TranslateHomePageState extends State<TranslateHomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  String _translatedText = '';
  Map<String, dynamic>? _analysis;
  String _fromLang = 'id';
  String _toLang = 'ng';
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _fromOptions = ['id', 'jw'];
  final Map<String, List<String>> _toOptions = {
    'id': ['ng', 'kl', 'ka'],
    'jw': ['id'],
  };

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  Future<void> _translate() async {
    if (_textController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan teks untuk diterjemahkan.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _translatedText = '';
      _analysis = null;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('https://kamus.mmcproject.web.id/api/idtojv');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': _textController.text,
          'from': _fromLang,
          'to': _toLang,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _translatedText = result['result'] ?? 'Tidak ada hasil.';
          _analysis = result['analysis'];
          _errorMessage = null;
        });
        _animationController.forward(from: 0);
      } else {
        setState(() {
          _errorMessage = 'Gagal menerjemahkan: Server error (${response.statusCode}).';
          _translatedText = '';
          _analysis = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _translatedText = '';
        _analysis = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cardWidth = isMobile ? double.infinity : 700.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'MMC Translator',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(), // Smooth scrolling effect
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan teks...',
                            // filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.translate, color: Colors.indigo),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          ),
                          maxLines: null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: DropdownButtonFormField<String>(
                                value: _fromLang,
                                decoration: InputDecoration(
                                  labelText: 'Dari Bahasa',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  // filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: _fromOptions
                                    .map((lang) => DropdownMenuItem(
                                        value: lang,
                                        child: Text(lang == 'id' ? 'Indonesia' : 'Jawa')))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _fromLang = value!;
                                    _toLang = _toOptions[_fromLang]!.first;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: DropdownButtonFormField<String>(
                                value: _toLang,
                                decoration: InputDecoration(
                                  labelText: 'Ke Bahasa',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  // filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: (_toOptions[_fromLang] ?? [])
                                    .map((lang) => DropdownMenuItem(
                                        value: lang,
                                        child: Text({
                                          'ng': 'Ngoko',
                                          'kl': 'Krama Lugu',
                                          'ka': 'Krama Alus',
                                          'id': 'Indonesia'
                                        }[lang]!)))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _toLang = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isLoading ? null : _translate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                _isLoading ? 'Menerjemahkan...' : 'Terjemahkan',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 30),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator()),
                    if (_translatedText.isNotEmpty && !_isLoading)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hasil Terjemahan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _translatedText,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_analysis != null && !_isLoading)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Analisis',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tokens → ${_analysis!['tokens']?.join(', ') ?? 'Tidak ada'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Stemmed Text → ${_analysis!['stemmed_text'] ?? 'Tidak ada'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Word Analysis',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_analysis!['word_analysis'] != null)
                                ...(_analysis!['word_analysis'] as List)
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final word = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Card(
                                      color: Colors.indigo.shade50,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Word ${index + 1}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Original → ${word['original']}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              'Translate Original → ${word['translate_original']}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              'Stemmed → ${word['stemmed'] ?? 'Tidak ada'}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              'Translate Stemmed → ${word['translate_stemmed'] ?? 'Tidak ada'}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      ),
                    if (_errorMessage != null && !_isLoading)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    const Divider(height: 40),
                    const Text(
                      'Kelompok MMC\nAnggota: Julius, Heru, Zani',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    super.dispose();
  }
}