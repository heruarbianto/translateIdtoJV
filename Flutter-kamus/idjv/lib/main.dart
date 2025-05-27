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
  String _fromLang = 'id';
  String _toLang = 'ng';
  bool _isLoading = false; // Track loading state
  String? _errorMessage; // Store error message

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
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    _animationController.forward();
  }

  Future<void> _translate() async {
    if (_textController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan teks untuk diterjemahkan.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _translatedText = '';
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
      ).timeout(const Duration(seconds: 10)); // Add timeout for network issues

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _translatedText = result['result'] ?? 'Tidak ada hasil.';
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal menerjemahkan: Server error (${response.statusCode}).';
          _translatedText = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _translatedText = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
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

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('MMC Translator',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan teks...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.translate),
                    ),
                    maxLines: null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _fromLang,
                          decoration: const InputDecoration(
                            labelText: 'Dari Bahasa',
                            border: OutlineInputBorder(),
                          ),
                          items: _fromOptions
                              .map((lang) => DropdownMenuItem(
                                  value: lang,
                                  child: Text(lang == 'id'
                                      ? 'Indonesia'
                                      : 'Jawa')))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _fromLang = value!;
                              _toLang = _toOptions[_fromLang]!.first;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _toLang,
                          decoration: const InputDecoration(
                            labelText: 'Ke Bahasa',
                            border: OutlineInputBorder(),
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
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _translate, // Disable button during loading
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isLoading ? 'Menerjemahkan...' : 'Terjemahkan',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_isLoading)
                    const CircularProgressIndicator(), // Show loading indicator
                  if (_translatedText.isNotEmpty && !_isLoading)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _translatedText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (_errorMessage != null && !_isLoading)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const Spacer(),
                  const Divider(height: 40),
                  const Text(
                    'Kelompok MMC\nAnggota: Julius, Heru, Zani',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
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
